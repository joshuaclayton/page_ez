module PageEz
  module MethodGenerators
    class HasManyStaticSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @block = block
        @evaluator_class = SelectorEvaluator.build(name, dynamic_options: dynamic_options, options: options, selector: selector)
      end

      def run(target)
        target.constructor_from_block(&@block).tap do |constructor|
          DefineHasManyResultMethods.new(
            @name,
            evaluator_class: @evaluator_class,
            constructor: constructor
          ).run(target)

          singularized_name = Pluralization.new(@name).singularize

          DefineHasOneResultMethods.new(
            "#{singularized_name}_matching",
            evaluator_class: @evaluator_class,
            constructor: constructor
          ).run(target)

          DefineHasOnePredicateMethods.new(
            "#{singularized_name}_matching",
            evaluator_class: @evaluator_class
          ).run(target)
        end
      end

      def selector_type
        :static
      end
    end
  end
end
