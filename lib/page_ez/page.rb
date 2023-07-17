require "capybara/dsl"
require "active_support/core_ext/class/attribute"

module PageEz
  class Page
    include DelegatesTo[:container]
    class_attribute :visitor, :macro_registrar

    self.visitor = PageVisitor.new
    self.macro_registrar = {}

    undef_method :select

    attr_reader :container

    def initialize(container = nil)
      @container = container || Class.new do
        include Capybara::DSL
      end.new
    end

    def self.method_added(name)
      if macro_registrar.key?(name)
        macro_registrar[name].run(self)
      end
    end

    def self.has_one(name, *args, **options, &block)
      construction_strategy = case [args.length, args.first]
      in [2, _] then
        StaticSelectorWithArgs.new(name, args.first.to_s, args[1], options, &block)
      in [1, Class] then
        ComposedClassSelector.new(name, args.first, options, &block)
      in [1, String] | [1, Symbol] then
        StaticSelector.new(name, args.first.to_s, options, &block)
      in [0, _] then
        DynamicSelector.new(name, options, &block)
      end

      visitor.process_macro(:has_one, name, construction_strategy.selector)

      construction_strategy.run(self)

      self.macro_registrar = macro_registrar.merge(name => construction_strategy)
    end

    def self.define_has_one_predicate_methods(evaluator_class)
      logged_define_method("has_#{evaluator_class.name}?") do |*args|
        evaluator = evaluator_class.run(args, target: self)

        has_css?(
          evaluator.selector,
          **evaluator.options
        )
      end

      logged_define_method("has_no_#{evaluator_class.name}?") do |*args|
        evaluator = evaluator_class.run(args, target: self)

        has_no_css?(
          evaluator.selector,
          **evaluator.options
        )
      end
    end

    def self.has_many(name, selector, dynamic_options = nil, **options, &block)
      visitor.process_macro(:has_many, name, selector)

      define_has_many(name, selector, dynamic_options, **options, &block)
    end

    def self.has_many_ordered(name, selector, dynamic_options = nil, **options, &block)
      visitor.process_macro(:has_many_ordered, name, selector)

      constructor = define_has_many(name, selector, dynamic_options, **options, &block)

      build_selector = ->(index) do
        # nth-of-type indices are 1-indexed rather than 0-indexed, so we add 1
        # to allow developers to still think 'in Ruby' when using this method
        "#{selector}:nth-of-type(#{index + 1})"
      end

      singularized_name = Pluralization.new(name).singularize

      logged_define_method("#{singularized_name}_at") do |index, *args|
        HasOneResult.new(
          container: container,
          selector: build_selector.call(index),
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      logged_define_method("has_#{singularized_name}_at?") do |index, *args|
        has_css?(
          build_selector.call(index),
          **Options.merge(options, dynamic_options, *args)
        )
      end
    end

    private_class_method def self.define_has_many(name, selector, dynamic_options = nil, **options, &block)
      constructor = constructor_from_block(&block)

      logged_define_method(name) do |*args|
        HasManyResult.new(
          container: container,
          selector: selector,
          options: Options.merge(options, dynamic_options, *args),
          constructor: constructor.method(:new)
        )
      end

      logged_define_method("has_#{name}_count?") do |count, *args|
        send(name, *args).has_count_of?(count)
      end

      constructor
    end

    def self.inherited(subclass)
      if ancestors.first == PageEz::Page
        visitor.reset
      end

      visitor.inherit_from(subclass)
    end

    def self.constructor_from_block(superclass = nil, &block)
      if block
        Class.new(superclass || self).tap do |klass|
          visitor.begin_block_evaluation
          klass.class_eval(&block)
          visitor.end_block_evaluation
        end
      elsif superclass
        superclass
      else
        Class.new(BasicObject) do
          def self.new(value)
            value
          end
        end
      end
    end

    def self.logged_define_method(name, &block)
      visitor.define_method(name)
      define_method(name, &block)
    end

    class StaticSelector
      def initialize(name, selector, options, &block)
        @decorated = StaticSelectorWithArgs.new(name, selector, nil, options, &block)
      end

      def selector
        @decorated.selector
      end

      def run(target)
        @decorated.run(target)
      end
    end

    class StaticSelectorWithArgs
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @dynamic_options = dynamic_options
        @options = options
        @block = block
      end

      def run(target)
        options = @options
        dynamic_options = @dynamic_options
        name = @name
        selector = @selector
        constructor = target.constructor_from_block(nil, &@block)
        evaluator_class = SelectorEvaluator.build(name, dynamic_options: dynamic_options, options: options, selector: selector)

        target.logged_define_method(name) do |*args|
          evaluator = evaluator_class.run(args, target: self)

          HasOneResult.new(
            container: container,
            selector: evaluator.selector,
            options: evaluator.options,
            constructor: constructor.method(:new)
          )
        end

        target.define_has_one_predicate_methods(evaluator_class)
      end
    end

    class DynamicSelector
      attr_reader :selector

      def initialize(name, options, &block)
        @run = false
        @name = name
        @options = options
        @block = block
      end

      def run(target)
        return if run?

        if target.method_defined?(@name)
          target.alias_method :"_#{@name}", @name
          target.undef_method @name
          @run = true

          selector = target.instance_method(:"_#{@name}")
        else
          selector = @name.to_s
        end

        StaticSelectorWithArgs.new(@name, selector, nil, @options, &@block).run(target)
      end

      private

      def run?
        @run
      end
    end

    class ComposedClassSelector
      attr_reader :selector

      def initialize(name, composed_class, options, &block)
        @name = name
        @composed_class = composed_class
        @options = options
        @block = block
      end

      def run(target)
        constructor = target.constructor_from_block(@composed_class, &@block)

        base_selector = @options.delete(:base_selector)

        target.logged_define_method(@name) do |*args|
          container = if base_selector
            find(base_selector)
          else
            self
          end

          constructor.new(container)
        end

        if base_selector
          target.define_has_one_predicate_methods(
            SelectorEvaluator.build(
              @name,
              dynamic_options: nil,
              options: @options,
              selector: base_selector
            )
          )
        end
      end
    end
  end
end
