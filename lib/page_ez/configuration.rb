module PageEz
  class Configuration
    VALID_MISMATCH_BEHAVIORS = [:warn, :raise, nil].freeze
    attr_accessor :logger
    attr_reader :on_pluralization_mismatch, :on_matcher_collision

    def initialize
      reset
    end

    def on_pluralization_mismatch=(value)
      if !VALID_MISMATCH_BEHAVIORS.include?(value)
        raise ArgumentError, "#{value.inspect} must be one of #{VALID_MISMATCH_BEHAVIORS}"
      end

      @on_pluralization_mismatch = value
    end

    def on_matcher_collision=(value)
      if !VALID_MISMATCH_BEHAVIORS.include?(value)
        raise ArgumentError, "#{value.inspect} must be one of #{VALID_MISMATCH_BEHAVIORS}"
      end

      @on_matcher_collision = value
    end

    def reset
      self.logger = NullLogger.new
      self.on_pluralization_mismatch = nil
      self.on_matcher_collision = :raise
    end
  end
end
