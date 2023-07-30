module PageEz
  module MethodGenerators
    class HasOneStaticSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @evaluator_class = SelectorEvaluator.build(name, dynamic_options: dynamic_options, options: options, selector: selector)
        @block = block
      end

      def run(target)
        constructor = target.constructor_from_block(&@block)

        DefineHasOneResultMethods.new(@name, evaluator_class: @evaluator_class, constructor: constructor).run(target)
        DefineHasOnePredicateMethods.new(@name, evaluator_class: @evaluator_class).run(target)
      end

      def selector_type
        :static
      end
    end
  end
end
