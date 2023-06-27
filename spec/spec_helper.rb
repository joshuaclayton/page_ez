# frozen_string_literal: true

require "page_ez"
require "sinatra/base"
require "capybara/rspec"
require_relative "support/app_generator"
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
    old_logger = PageEz.configuration.logger

    example.run
  ensure
    PageEz.configure do |config|
      config.logger = old_logger
    end
  end
end
