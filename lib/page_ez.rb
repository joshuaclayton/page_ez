# frozen_string_literal: true

require_relative "page_ez/version"
require_relative "page_ez/configuration"
require_relative "page_ez/null_logger"
require_relative "page_ez/page"
require_relative "page_ez/pluralization"
require_relative "page_ez/options"
require_relative "page_ez/has_one_result"
require_relative "page_ez/has_many_result"

module PageEz
  class Error < StandardError; end

  class PluralizationMismatchError < StandardError; end

  class DuplicateElementDeclarationError < StandardError; end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end
end
