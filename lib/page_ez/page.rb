require "capybara/dsl"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/module/delegation"

module PageEz
  class Page
    include DelegatesTo[:container]
    class_attribute :visitor, :macro_registrar, :nested_macro, :container_base_selector

    self.visitor = PageVisitor.new
    self.macro_registrar = {}
    self.nested_macro = false
    self.container_base_selector = nil

    undef_method :select

    def container
      if container_base_selector
        @container.find(container_base_selector)
      else
        @container
      end
    end

    def self.base_selector(value)
      self.container_base_selector = value
    end

    def self.contains(page_object, only: nil)
      delegation_target = :"__page_object_#{page_object.object_id}__"

      has_one(delegation_target, page_object)

      if only
        methods_delegated_that_do_not_exist = only - page_object.instance_methods(false)
        if methods_delegated_that_do_not_exist.any?
          raise NoMethodError, "Attempting to delegate non-existent method(s) to #{page_object}: #{methods_delegated_that_do_not_exist.join(", ")}"
        end
      end

      delegate(*(only || page_object.instance_methods(false)), to: delegation_target)
    end

    def initialize(container = nil)
      @container = container || Class.new do
        include Capybara::DSL
      end.new
    end

    def self.method_added(name)
      visitor.track_method_added(name, macro_registrar[name])

      if macro_registrar.key?(name)
        macro_registrar[name].run(self)
      end
    end

    def self.delegate(...)
      super(...).tap do |method_names|
        method_names.each do |method_name|
          visitor.track_method_delegated(method_name)
        end
      end
    end

    def self.method_undefined(name)
      visitor.track_method_undefined(name)
    end

    def self.rename_method(from:, to:)
      alias_method to, from
      undef_method from
      visitor.track_method_renamed(from, to)
    end

    def self.has_one(name, *args, **options, &block)
      construction_strategy = case [args.length, args.first]
      in [2, _] then
        MethodGenerators::HasOneStaticSelector.new(name, args.first.to_s, args[1], options, &block)
      in [1, Class] then
        MethodGenerators::HasOneComposedClass.new(name, args.first, options, &block)
      in [1, String] | [1, Symbol] then
        MethodGenerators::HasOneStaticSelector.new(name, args.first.to_s, nil, options, &block)
      in [0, _] then
        MethodGenerators::HasOneDynamicSelector.new(name, options, &block)
      end

      visitor.process_macro(:has_one, name, construction_strategy)

      construction_strategy.run(self)

      self.macro_registrar = macro_registrar.merge(name => construction_strategy)
    end

    def self.has_many(name, *args, **options, &block)
      construction_strategy = case [args.length, args.first]
      in [2, _] then
        MethodGenerators::HasManyStaticSelector.new(name, args.first.to_s, args[1], options, &block)
      in [1, String] | [1, Symbol] then
        MethodGenerators::HasManyStaticSelector.new(name, args.first.to_s, nil, options, &block)
      in [0, _] then
        MethodGenerators::HasManyDynamicSelector.new(name, options, &block)
      end

      visitor.process_macro(:has_many, name, construction_strategy)

      construction_strategy.run(self)

      self.macro_registrar = macro_registrar.merge(name => construction_strategy)
    end

    def self.has_many_ordered(name, *args, **options, &block)
      construction_strategy = case [args.length, args.first]
      in [2, _] then
        MethodGenerators::HasManyOrderedSelector.new(name, args.first.to_s, args[1], options, &block)
      in [1, String] | [1, Symbol] then
        MethodGenerators::HasManyOrderedSelector.new(name, args.first.to_s, nil, options, &block)
      in [0, _] then
        MethodGenerators::HasManyOrderedDynamicSelector.new(name, options, &block)
      end

      visitor.process_macro(:has_many_ordered, name, construction_strategy)

      construction_strategy.run(self)

      self.macro_registrar = macro_registrar.merge(name => construction_strategy)
    end

    def self.inherited(subclass)
      if !nested_macro
        visitor.reset
      end

      visitor.inherit_from(subclass)
    end

    def self.constructor_from_block(superclass = nil, &block)
      if block
        self.nested_macro = true
        Class.new(superclass || self).tap do |klass|
          visitor.begin_block_evaluation
          klass.macro_registrar = {}
          klass.container_base_selector = nil
          klass.class_eval(&block)
          visitor.end_block_evaluation
          self.nested_macro = false
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
  end
end
