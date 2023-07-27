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
          if base_selector
            Class.new(constructor).tap do |new_constructor|
              new_constructor.base_selector base_selector
            end.new(self)
          else
            constructor.new(self)
          end
        end

        if base_selector
          evaluator_class = SelectorEvaluator.build(
            @name,
            dynamic_options: nil,
            options: @options,
            selector: base_selector
          )
          DefineHasOnePredicateMethods.new(@name, evaluator_class: evaluator_class).run(target)
        end
      end
    end
  end
end
