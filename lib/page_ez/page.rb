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
        MethodGenerators::HasOneStaticSelector.new(name, args.first.to_s, args[1], options, &block)
      in [1, Class] then
        MethodGenerators::HasOneComposedClass.new(name, args.first, options, &block)
      in [1, String] | [1, Symbol] then
        MethodGenerators::HasOneStaticSelector.new(name, args.first.to_s, nil, options, &block)
      in [0, _] then
        MethodGenerators::HasOneDynamicSelector.new(name, options, &block)
      end

      visitor.process_macro(:has_one, name, construction_strategy.selector)

      construction_strategy.run(self)

      self.macro_registrar = macro_registrar.merge(name => construction_strategy)
    end

    def self.has_many(name, selector, dynamic_options = nil, **options, &block)
      visitor.process_macro(:has_many, name, selector)

      MethodGenerators::HasManyStaticSelector.new(name, selector, dynamic_options, options, &block).run(self)
    end

    def self.has_many_ordered(name, selector, dynamic_options = nil, **options, &block)
      visitor.process_macro(:has_many_ordered, name, selector)

      MethodGenerators::HasManyOrderedSelector.new(name, selector, dynamic_options, options, &block).run(self)
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
  end
end
