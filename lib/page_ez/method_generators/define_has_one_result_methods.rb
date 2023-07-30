require_relative "identity_processor"

module PageEz
  module MethodGenerators
    class DefineHasOneResultMethods
      def initialize(name, evaluator_class:, constructor:, processor: IdentityProcessor)
        @name = name
        @evaluator_class = evaluator_class
        @processor = processor
        @constructor = constructor
      end

      def run(target)
        evaluator_class = @evaluator_class
        processor = @processor
        constructor = @constructor

        target.logged_define_method(@name) do |*args|
          evaluator = evaluator_class.run(processor.run_args(args), target: self)

          PageEz::HasOneResult.new(
            container: container,
            selector: processor.selector(evaluator.selector, args),
            options: evaluator.options,
            constructor: constructor.method(:new)
          )
        end
      end
    end
  end
end
