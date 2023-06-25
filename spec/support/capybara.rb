module CapybaraHelpers
  def with_max_wait_time(seconds:)
    original_wait_time = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = seconds
    yield
  ensure
    Capybara.default_max_wait_time = original_wait_time
  end
end

RSpec.configure do |config|
  config.include CapybaraHelpers, type: :feature
end
