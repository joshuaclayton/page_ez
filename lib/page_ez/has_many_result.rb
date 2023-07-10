module PageEz
  class HasManyResult
    include DelegatesTo[:@result]

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
  end
end
