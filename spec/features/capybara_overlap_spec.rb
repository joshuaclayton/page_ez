require "spec_helper"

RSpec.describe "Declaring elements that overlap with Capybara matchers", type: :feature do
  it "warns that those matchers will be used instead of the predicate methods" do
    PageEz.configure do |config|
      config.on_matcher_collision = :warn
    end

    logger = configure_fake_logger

    Class.new(PageEz::Page) do
      has_one :thing, "section" do
        has_one :title, "h3"
      end
    end

    expect(logger.warns).to contain_in_order(
      "  has_one :title, \"h3\" will conflict with Capybara's `have_title` matcher"
    )
  end

  it "raises when configured to raise" do
    PageEz.configure do |config|
      config.on_matcher_collision = :raise
    end

    expect do
      Class.new(PageEz::Page) do
        has_one :thing, "section" do
          has_one :title, "h3"
        end
      end
    end.to raise_error(PageEz::MatcherCollisionError, /will conflict/)
  end

  it "does not raise or warn when configured to ignore" do
    PageEz.configure do |config|
      config.on_matcher_collision = nil
    end

    logger = configure_fake_logger

    Class.new(PageEz::Page) do
      has_one :thing, "section" do
        has_one :title, "h3"
      end
    end

    expect(logger.warns).to be_empty
  end

  it "does not raise if Capybara's RSpec matchers are not available" do
    without_capybara_rspec do
      PageEz.configure do |config|
        config.on_matcher_collision = :raise
      end

      expect do
        Class.new(PageEz::Page) do
          has_one :thing, "section" do
            has_one :title, "h3"
          end
        end
      end.not_to raise_error
    end

    expect(defined?(Capybara::RSpecMatchers)).to eq "constant"
  end

  def without_capybara_rspec
    Object.send :const_set, "PageEzTempConstant", Capybara::RSpecMatchers
    Capybara.send :remove_const, "RSpecMatchers"
    yield
  ensure
    Capybara.send :const_set, "RSpecMatchers", Object.const_get(:PageEzTempConstant)
    Object.send :remove_const, "PageEzTempConstant"
  end
end
