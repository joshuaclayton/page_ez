module PageEz
  class SelectorEvaluator
    def initialize(name, args, dynamic_options:, selector:, target:)
      @name = name
      @args = args
      @dynamic_options = dynamic_options
      @selector = if selector.respond_to?(:bind)
        selector.bind(target)
      else
        selector
      end
    end

    def selector
      if dynamic_selector?
        args = []

        if @selector.parameters.first[0] == :opt
          args << @name
        end

        if selector_kwargs.any?
          @selector.call(*args, **kwargs.slice(*selector_kwargs))
        else
          @selector.call(*args)
        end
      else
        @selector
      end
    end

    def args
      if @args.any? && kwargs.any?
        cloned_args = @args.dup
        cloned_args[-1] = kwargs.except(*selector_kwargs).merge(kwargs.slice(*dynamic_kwargs))
        cloned_args
      else
        @args
      end
    end

    private

    def dynamic_selector?
      @selector.respond_to?(:parameters) && @selector.respond_to?(:call)
    end

    def dynamic_kwargs
      Parameters.build(@dynamic_options).keyword_args
    end

    def selector_kwargs
      Parameters.build(@selector).keyword_args
    end

    def kwargs
      @args.last.is_a?(Hash) ? @args.last : {}
    end
  end
end
