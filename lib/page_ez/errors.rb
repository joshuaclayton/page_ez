module PageEz
  class Error < StandardError; end

  class PluralizationMismatchError < StandardError; end

  class DuplicateElementDeclarationError < StandardError; end
end
