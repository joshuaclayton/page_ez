# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov.info"
end

SimpleCov.start do
  add_filter "spec/"

  if ENV["CI"]
    formatter SimpleCov::Formatter::LcovFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter
    ])
  end
end

require "page_ez"
require "sinatra/base"
require "capybara/rspec"
require_relative "support/app_generator"
require_relative "support/fake_logger"
require_relative "support/capybara"
require_relative "support/matchers/contain_in_order"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around do |example|
    example.run
  ensure
    PageEz.configuration.reset
  end
end
