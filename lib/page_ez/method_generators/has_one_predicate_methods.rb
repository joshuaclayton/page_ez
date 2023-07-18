module PageEz
  module MethodGenerators
    class HasOnePredicateMethods
      def initialize(evaluator_class)
        @evaluator_class = evaluator_class
      end

      def run(target)
        evaluator_class = @evaluator_class

        target.logged_define_method("has_#{evaluator_class.name}?") do |*args|
          evaluator = evaluator_class.run(args, target: self)

          has_css?(
            evaluator.selector,
            **evaluator.options
          )
        end

        target.logged_define_method("has_no_#{evaluator_class.name}?") do |*args|
          evaluator = evaluator_class.run(args, target: self)

          has_no_css?(
            evaluator.selector,
            **evaluator.options
          )
        end
      end
    end
  end
end
