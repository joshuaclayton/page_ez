module PageEz
  module MethodGenerators
    class HasOneStaticSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @dynamic_options = dynamic_options
        @options = options
        @block = block
      end

      def run(target)
        options = @options
        dynamic_options = @dynamic_options
        name = @name
        selector = @selector
        constructor = target.constructor_from_block(&@block)
        evaluator_class = SelectorEvaluator.build(name, dynamic_options: dynamic_options, options: options, selector: selector)

        target.logged_define_method(name) do |*args|
          evaluator = evaluator_class.run(args, target: self)

          HasOneResult.new(
            container: container,
            selector: evaluator.selector,
            options: evaluator.options,
            constructor: constructor.method(:new)
          )
        end

        HasOnePredicateMethods.new(evaluator_class).run(target)
      end
    end
  end
end
