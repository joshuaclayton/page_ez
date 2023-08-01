require "spec_helper"

RSpec.describe "generating broken CSS selectors", :feature do
  it "provides more context around what selector was used" do
    page = build_page(<<-HTML)
    <section>Bogus</section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :dynamic_section
      has_one :section_assuming_dynamic_section_can_be_interpolated
      has_many :sections_assuming_dynamic_section_can_be_interpolated

      def dynamic_section(_)
        "section"
      end

      def section_assuming_dynamic_section_can_be_interpolated
        # dynamic_section("value") returns a HasOneResult rather than a string,
        # which is rendered as "#<PageEz::HasOneResult...> [data-role=has_one-wont-work]"
        "#{dynamic_section("value")} [data-role=has_one-wont-work]"
      end

      def sections_assuming_dynamic_section_can_be_interpolated
        # dynamic_section("value") returns a HasOneResult rather than a string,
        # which is rendered as "#<PageEz::HasOneResult...> [data-role=has_many-wont-work]"
        "#{dynamic_section("value")} [data-role=has_many-wont-work]"
      end
    end.new(page)

    page.visit "/"

    expect {
      test_page.section_assuming_dynamic_section_can_be_interpolated
    }.to raise_error(PageEz::InvalidSelectorError, /^Invalid selector '#<PageEz::HasOneResult.*\[data-role=has_one-wont-work\]'/)

    expect {
      test_page.has_section_assuming_dynamic_section_can_be_interpolated?
    }.to raise_error(PageEz::InvalidSelectorError, /^Invalid selector '#<PageEz::HasOneResult.*\[data-role=has_one-wont-work\]'/)

    expect {
      test_page.has_no_section_assuming_dynamic_section_can_be_interpolated?
    }.to raise_error(PageEz::InvalidSelectorError, /^Invalid selector '#<PageEz::HasOneResult.*\[data-role=has_one-wont-work\]'/)

    expect {
      test_page.sections_assuming_dynamic_section_can_be_interpolated
    }.to raise_error(PageEz::InvalidSelectorError, /^Invalid selector '#<PageEz::HasOneResult.*\[data-role=has_many-wont-work\]'/)

    expect {
      test_page.has_sections_assuming_dynamic_section_can_be_interpolated_count?(1)
    }.to raise_error(PageEz::InvalidSelectorError, /^Invalid selector '#<PageEz::HasOneResult.*\[data-role=has_many-wont-work\]'/)
  end
end
