module PageEz
  module MethodGenerators
    class HasOneDynamicSelector
      attr_reader :selector

      def initialize(name, options, &block)
        @run = false
        @name = name
        @options = options
        @block = block
      end

      def run(target)
        return if run?

        if target.method_defined?(@name)
          target.alias_method :"_#{@name}", @name
          target.undef_method @name
          @run = true

          @selector = target.instance_method(:"_#{@name}")
        else
          @selector = @name.to_s
        end

        HasOneStaticSelector.new(@name, @selector, nil, @options, &@block).run(target)
      end

      private

      def run?
        @run
      end
    end
  end
end
