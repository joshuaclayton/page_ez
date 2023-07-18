module PageEz
  module MethodGenerators
    class HasOneComposedClass
      attr_reader :selector

      def initialize(name, composed_class, options, &block)
        @name = name
        @composed_class = composed_class
        @options = options
        @block = block
      end

      def run(target)
        constructor = target.constructor_from_block(@composed_class, &@block)

        base_selector = @options.delete(:base_selector)

        target.logged_define_method(@name) do |*args|
          container = if base_selector
            find(base_selector)
          else
            self
          end

          constructor.new(container)
        end

        if base_selector
          evaluator_class = SelectorEvaluator.build(
            @name,
            dynamic_options: nil,
            options: @options,
            selector: base_selector
          )
          HasOnePredicateMethods.new(evaluator_class).run(target)
        end
      end
    end
  end
end
