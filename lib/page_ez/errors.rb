module PageEz
  class Error < StandardError; end

  class PluralizationMismatchError < StandardError; end

  class MatcherCollisionError < StandardError; end

  class DuplicateElementDeclarationError < StandardError; end

  class InvalidSelectorError < StandardError; end

  def self.reraise_selector_error(selector)
    yield
  rescue Nokogiri::CSS::SyntaxError => e
    raise InvalidSelectorError, "Invalid selector '#{selector}':\n#{e.message}"
  end
end
