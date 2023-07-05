module FakeLogger
  def configure_fake_logger
    logger = Class.new do
      attr_reader :debugs, :infos, :warns

      def initialize
        reset
      end

      def debug(message)
        @debugs << message
      end

      def info(message)
        @infos << message
      end

      def warn(message)
        @warns << message
      end

      def reset
        @debugs = []
        @infos = []
        @warns = []
      end
    end.new

    PageEz.configure do |config|
      config.logger = logger
    end

    logger
  end
end

RSpec.configure do |config|
  config.include FakeLogger
end
