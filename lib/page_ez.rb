# frozen_string_literal: true

require_relative "page_ez/version"
require_relative "page_ez/errors"
require_relative "page_ez/configuration"
require_relative "page_ez/null_logger"
require_relative "page_ez/delegates_to"
require_relative "page_ez/parameters"
require_relative "page_ez/selector_evaluator"
require_relative "page_ez/method_generators/define_has_many_result_methods"
require_relative "page_ez/method_generators/define_has_one_result_methods"
require_relative "page_ez/method_generators/define_has_one_predicate_methods"
require_relative "page_ez/method_generators/identity_processor"
require_relative "page_ez/method_generators/has_one_static_selector"
require_relative "page_ez/method_generators/has_one_dynamic_selector"
require_relative "page_ez/method_generators/has_one_composed_class"
require_relative "page_ez/method_generators/has_many_dynamic_selector"
require_relative "page_ez/method_generators/has_many_ordered_dynamic_selector"
require_relative "page_ez/method_generators/has_many_ordered_selector"
require_relative "page_ez/method_generators/has_many_static_selector"
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
