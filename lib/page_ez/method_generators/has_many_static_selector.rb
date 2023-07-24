module PageEz
  module MethodGenerators
    class HasManyStaticSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @dynamic_options = dynamic_options
        @options = options
        @block = block
      end

      def run(target)
        constructor = target.constructor_from_block(&@block)
        name = @name
        selector = @selector
        options = @options
        dynamic_options = @dynamic_options

        evaluator_class = SelectorEvaluator.build(name, dynamic_options: dynamic_options, options: options, selector: selector)

        target.logged_define_method(name) do |*args|
          evaluator = evaluator_class.run(args, target: self)

          HasManyResult.new(
            container: container,
            selector: evaluator.selector,
            options: evaluator.options,
            constructor: constructor.method(:new)
          )
        end

        target.logged_define_method("has_#{name}_count?") do |count, *args|
          send(name, *args).has_count_of?(count)
        end

        constructor
      end

      def selector_type
        :static
      end
    end
  end
end
