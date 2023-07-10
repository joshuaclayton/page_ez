module PageEz
  class HasOneResult
    include DelegatesTo[:@result]

    def initialize(container:, selector:, options:, constructor:)
      @result = constructor.call(
        container.find(
          selector,
          **options
        )
      )
    end
  end
end
