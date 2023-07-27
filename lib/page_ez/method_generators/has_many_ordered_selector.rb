module PageEz
  module MethodGenerators
    class HasManyOrderedSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @core_selector = HasManyStaticSelector.new(name, selector, dynamic_options, options, &block)
        @evaluator_class = SelectorEvaluator.build(@name, dynamic_options: dynamic_options, options: options, selector: selector)
      end

      def run(target)
        singularized_name = Pluralization.new(@name).singularize

        constructor = @core_selector.run(target)

        DefineHasOneResultMethods.new(
          "#{singularized_name}_at",
          evaluator_class: @evaluator_class,
          constructor: constructor,
          processor: IndexedProcessor
        ).run(target)

        DefineHasOnePredicateMethods.new(
          "#{singularized_name}_at",
          evaluator_class: @evaluator_class,
          processor: IndexedProcessor
        ).run(target)
      end

      def selector_type
        @core_selector.selector_type
      end

      class IndexedProcessor
        def self.run_args(args)
          args[1..]
        end

        def self.selector(selector, args)
          "#{selector}:nth-of-type(#{args[0] + 1})"
        end
      end
    end
  end
end
