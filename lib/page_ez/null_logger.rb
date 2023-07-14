module PageEz
  class NullLogger
    def debug(msg)
      puts "DEBUG: #{msg}"
    end

    def info(*)
    end

    def warn(*)
    end
  end
end
