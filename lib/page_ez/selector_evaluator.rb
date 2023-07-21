module PageEz
  class SelectorEvaluator
    def self.build(name, dynamic_options:, options:, selector:)
      run_def = ->(args, target:) do
        PageEz::SelectorEvaluator.new(name, args, dynamic_options: dynamic_options, options: options, selector: selector, target: target)
      end

      name_def = -> { name }

      Class.new.tap do |klass|
        klass.define_singleton_method(:run, &run_def)
        klass.define_singleton_method(:name, &name_def)
      end
    end

    def initialize(name, args, dynamic_options:, options:, selector:, target:)
      @name = name
      @args = args
      @dynamic_options = dynamic_options
      @options = options
      @selector = if selector.respond_to?(:bind)
        selector.bind(target)
      else
        selector
      end
    end

    def selector
      if dynamic_selector?
        if selector_args.none?
          @selector.call(**kwargs.slice(*selector_kwargs))
        else
          @selector.call(*args[0..selector_args.length - 1], **kwargs.slice(*selector_kwargs))
        end
      else
        @selector
      end
    end

    def options
      Options.merge(@options, @dynamic_options, *args[selector_args.length..])
    end

    private

    def args
      if @args.any? && kwargs.any?
        cloned_args = @args.dup
        cloned_args[-1] = kwargs.except(*selector_kwargs).merge(kwargs.slice(*dynamic_kwargs))
        cloned_args
      else
        @args
      end
    end

    def dynamic_selector?
      @selector.respond_to?(:parameters) && @selector.respond_to?(:call)
    end

    def dynamic_kwargs
      Parameters.build(@dynamic_options).keyword_args
    end

    def selector_kwargs
      Parameters.build(@selector).keyword_args
    end

    def selector_args
      Parameters.build(@selector).non_keyword_args
    end

    def kwargs
      @args.last.is_a?(Hash) ? @args.last : {}
    end
  end
end
