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
end
