# frozen_string_literal: true

require_relative "page_ez/version"
require_relative "page_ez/errors"
require_relative "page_ez/configuration"
require_relative "page_ez/null_logger"
require_relative "page_ez/delegates_to"
require_relative "page_ez/visitors/matcher_collision_visitor"
require_relative "page_ez/visitors/depth_visitor"
require_relative "page_ez/visitors/debug_visitor"
require_relative "page_ez/visitors/registered_name_visitor"
require_relative "page_ez/visitors/macro_pluralization_visitor"
require_relative "page_ez/page_visitor"
require_relative "page_ez/page"
require_relative "page_ez/pluralization"
require_relative "page_ez/options"
require_relative "page_ez/has_one_result"
require_relative "page_ez/has_many_result"

module PageEz
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end
end
