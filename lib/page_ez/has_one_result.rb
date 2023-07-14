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
      puts "result: #{@result}"
      puts "result: #{@result.methods}"
      puts "result: #{@result.respond_to?(:heading)}"
    end
  end
end
