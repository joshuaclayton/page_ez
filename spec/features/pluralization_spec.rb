require "spec_helper"

RSpec.describe "Declarations with improper pluralization" do
  it "warns when pluralization doesn't align with macro" do
    logger = configure_fake_logger

    PageEz.configure do |config|
      config.on_pluralization_mismatch = :warn
    end

    Class.new(PageEz::Page) do
      has_one :lists, "ul" do
        has_many :item, "li"
        has_many_ordered :thing, "li"
      end
    end

    expect(logger.warns).to contain_in_order(
      "consider singularizing :lists in has_one :lists, \"ul\"",
      "  consider pluralizing :item in has_many :item, \"li\"",
      "  consider pluralizing :thing in has_many_ordered :thing, \"li\""
    )
  end

  it "raises when pluralization doesn't align with macro" do
    PageEz.configure do |config|
      config.on_pluralization_mismatch = :raise
    end

    expect do
      Class.new(PageEz::Page) do
        has_one :lists, "ul" do
          has_many :item, "li"
        end
      end
    end.to raise_error(PageEz::PluralizationMismatchError, /consider singularizing :lists in has_one :lists, "ul"/)
  end

  it "does not warn when pluralization doesn't align with macro and config is disabled" do
    logger = configure_fake_logger

    PageEz.configure do |config|
      config.on_pluralization_mismatch = nil
    end

    Class.new(PageEz::Page) do
      has_one :lists, "ul" do
        has_many :item, "li"
      end
    end

    expect(logger.warns).not_to include(/consider singularizing :lists in has_one :lists, "ul"/)
    expect(logger.warns).not_to include(/consider pluralizing :item in has_many :item, "li"/)
  end
end
