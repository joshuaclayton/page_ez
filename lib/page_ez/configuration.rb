module PageEz
  class Configuration
    VALID_PLURALIZATION_MISMATCH_BEHAVIORS = [:warn, :raise, nil].freeze
    attr_accessor :logger
    attr_reader :on_pluralization_mismatch

    def initialize
      reset
    end

    def on_pluralization_mismatch=(value)
      if !VALID_PLURALIZATION_MISMATCH_BEHAVIORS.include?(value)
        raise ArgumentError, "#{value.inspect} must be one of #{VALID_PLURALIZATION_MISMATCH_BEHAVIORS}"
      end

      @on_pluralization_mismatch = value
    end

    def reset
      self.logger = NullLogger.new
      self.on_pluralization_mismatch = nil
    end
  end
end
