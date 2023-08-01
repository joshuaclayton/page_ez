module PageEz
  module MethodGenerators
    class DefineHasOnePredicateMethods
      def initialize(name, evaluator_class:, processor: IdentityProcessor)
        @name = name
        @evaluator_class = evaluator_class
        @processor = processor
      end

      def run(target)
        evaluator_class = @evaluator_class
        processor = @processor

        target.logged_define_method("has_#{@name}?") do |*args|
          evaluator = evaluator_class.run(processor.run_args(args), target: self)

          selector = processor.selector(evaluator.selector, args)

          PageEz.reraise_selector_error(selector) do
            has_css?(
              selector,
              **evaluator.options
            )
          end
        end

        target.logged_define_method("has_no_#{@name}?") do |*args|
          evaluator = evaluator_class.run(processor.run_args(args), target: self)

          selector = processor.selector(evaluator.selector, args)

          PageEz.reraise_selector_error(selector) do
            has_no_css?(
              selector,
              **evaluator.options
            )
          end
        end
      end
    end
  end
end
