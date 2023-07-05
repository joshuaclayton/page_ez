module PageEz
  class Configuration
    attr_accessor :logger

    def initialize
      reset
    end

    def reset
      self.logger = NullLogger.new
    end
  end
end
