require "capybara/dsl"
require "active_support/core_ext/class/attribute"

module PageEz
  class Page
    include DelegatesTo[:container]
    class_attribute :visitor

    self.visitor = PageVisitor.new

    undef_method :select

    attr_reader :container

    def initialize(container = nil)
      @container = container || Class.new do
        include Capybara::DSL
      end.new
    end

    def self.has_one(name, *args, **options, &block)
      selector = nil
      dynamic_options = nil
      composed_class = nil

      case [args.length, args.first]
      in [2, _] then selector, dynamic_options = args
      in [1, Class] then composed_class = args.first
      in [1, String] | [1, Symbol] then selector = args.first.to_s
      in [0, _] then selector = name.to_s
      end

      visitor.process_macro(:has_one, name, selector)

      constructor = constructor_from_block(composed_class, &block)

      if selector
        logged_define_method(name) do |*args|
          HasOneResult.new(
            container: container,
            selector: selector,
            options: Options.merge(options, dynamic_options, *args),
            constructor: constructor.method(:new)
          )
        end

        define_has_one_predicate_methods(name, selector, options, dynamic_options)
      elsif composed_class
        base_selector = options.delete(:base_selector)

        logged_define_method(name) do |*args|
          container = if base_selector
            find(base_selector)
          else
            self
          end

          constructor.new(container)
        end

        if base_selector
          define_has_one_predicate_methods(name, base_selector, options, dynamic_options)
        end
      end
    end

    private_class_method def self.define_has_one_predicate_methods(name, selector, options, dynamic_options)
      logged_define_method("has_#{name}?") do |*args|
        has_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
        )
      end

      logged_define_method("has_no_#{name}?") do |*args|
        has_no_css?(
          selector,
          **Options.merge(options, dynamic_options, *args)
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

    private_class_method def self.constructor_from_block(superclass = nil, &block)
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

    private_class_method def self.logged_define_method(name, &block)
      visitor.define_method(name)
      define_method(name, &block)
    end
  end
end
