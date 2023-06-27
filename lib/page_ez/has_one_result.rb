module PageEz
  class HasOneResult
    def initialize(container:, selector:, options:, constructor:)
      @result = constructor.call(
        container.find(
          selector,
          **options
        )
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
