require "active_support/core_ext/string/inflections"

module PageEz
  class Pluralization
    def initialize(word)
      @word = word.to_s
    end

    def singularize
      @word.singularize
    end

    def pluralize
      @word.pluralize
    end

    def plural?
      @word == pluralize && @word != singularize
    end

    def singular?
      !plural?
    end
  end
end
