require_relative "identity_processor"

module PageEz
  module MethodGenerators
    class DefineHasManyResultMethods
      def initialize(name, evaluator_class:, constructor:, processor: IdentityProcessor)
        @name = name
        @evaluator_class = evaluator_class
        @constructor = constructor
        @processor = processor
      end

      def run(target)
        name = @name
        evaluator_class = @evaluator_class
        constructor = @constructor
        processor = @processor

        target.logged_define_method(name) do |*args|
          evaluator = evaluator_class.run(processor.run_args(args), target: self)

          selector = processor.selector(evaluator.selector, args)

          PageEz.reraise_selector_error(selector) do
            PageEz::HasManyResult.new(
              container: container,
              selector: selector,
              options: evaluator.options,
              constructor: constructor.method(:new)
            )
          end
        end

        target.logged_define_method("has_#{name}_count?") do |count, *args|
          send(name, *args).has_count_of?(count)
        end

        target.logged_define_method("has_#{name}?") do |*args|
          send(name, *args).has_any_elements?
        end

        target.logged_define_method("has_no_#{name}?") do |*args|
          send(name, *args).has_no_elements?
        end
      end
    end
  end
end
