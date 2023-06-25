# frozen_string_literal: true

require_relative "page_ez/version"
require_relative "page_ez/page"
require_relative "page_ez/decorate_element_with_block"
require_relative "page_ez/has_one_result"
require_relative "page_ez/has_many_result"

module PageEz
  class Error < StandardError; end
end
