module PageEz
  class HasManyResult
    def initialize(container:, selector:, options:, constructor:)
      @container = container
      @selector = selector
      @options = options
      @result = container.all(
        selector,
        **options
      ).map do |element|
        constructor.call(element)
      end
    end

    def has_count_of?(count)
      @container.has_css?(
        @selector,
        **@options.merge(count: count)
      )
    end

    private

    def method_missing(*args, **kwargs, &block)
      if @result.respond_to?(args[0])
        @result.send(*args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @result.respond_to?(method_name, include_private) || super
    end
  end
end
