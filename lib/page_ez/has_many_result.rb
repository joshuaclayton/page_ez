module PageEz
  class HasManyResult
    def initialize(container:, selector:, options:, &block)
      @container = container
      @selector = selector
      @options = options
      @result = container.all(
        selector,
        **options
      ).map do |element|
        DecorateElementWithBlock.run(element, &block)
      end
    end

    def has_count_of?(count)
      @container.has_css?(
        @selector,
        **@options.merge(count: count)
      )
    end

    private

    def method_missing(method_name, *args, &block)
      if @result.respond_to?(method_name)
        @result.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @result.respond_to?(method_name, include_private) || super
    end
  end
end
