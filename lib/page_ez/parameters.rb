module PageEz
  class Parameters
    def self.build(block)
      if block&.respond_to?(:parameters) && block&.respond_to?(:arity)
        new(block)
      else
        NullParameters.new
      end
    end

    def keyword_args
      @block.parameters.filter_map do |type, name|
        param = Parameter.new(type, name)
        param.name if param.kwarg?
      end
    end

    def non_keyword_args
      @block.parameters.filter_map do |type, name|
        param = Parameter.new(type, name)
        param.name if !param.kwarg?
      end
    end

    private_class_method :new

    def initialize(block)
      @block = block
    end

    class NullParameters
      def keyword_args
        []
      end

      def non_keyword_args
        []
      end
    end

    class Parameter
      attr_reader :name

      def initialize(type, name)
        @type = type
        @name = name
      end

      def kwarg?
        @type == :keyreq || @type == :key
      end
    end
  end
end
