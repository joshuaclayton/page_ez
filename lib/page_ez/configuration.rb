module PageEz
  class Configuration
    attr_accessor :logger

    def initialize
      @logger = NullLogger.new
    end
  end
end
