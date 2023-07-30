module PageEz::MethodGenerators
  class IdentityProcessor
    def self.run_args(args)
      args
    end

    def self.selector(value, _)
      value
    end
  end
end
