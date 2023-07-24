module PageEz
  module MethodGenerators
    class HasManyOrderedSelector
      attr_reader :selector

      def initialize(name, selector, dynamic_options, options, &block)
        @name = name
        @selector = selector
        @dynamic_options = dynamic_options
        @options = options
        @block = block
        @base_selector = HasManyStaticSelector.new(name, selector, dynamic_options, options, &block)
      end

      def run(target)
        build_selector = ->(selector, index) do
          # nth-of-type indices are 1-indexed rather than 0-indexed, so we add 1
          # to allow developers to still think 'in Ruby' when using this method
          "#{selector}:nth-of-type(#{index + 1})"
        end

        singularized_name = Pluralization.new(@name).singularize

        options = @options
        dynamic_options = @dynamic_options
        constructor = @base_selector.run(target)

        evaluator_class = SelectorEvaluator.build(@name, dynamic_options: dynamic_options, options: options, selector: selector)

        target.logged_define_method("#{singularized_name}_at") do |index, *args|
          evaluator = evaluator_class.run(args, target: self)
          HasOneResult.new(
            container: container,
            selector: build_selector[evaluator.selector, index],
            options: evaluator.options,
            constructor: constructor.method(:new)
          )
        end

        target.logged_define_method("has_#{singularized_name}_at?") do |index, *args|
          evaluator = evaluator_class.run(args, target: self)

          has_css?(
            build_selector[evaluator.selector, index],
            **evaluator.options
          )
        end
      end
    end
  end
end
