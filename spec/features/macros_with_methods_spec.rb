require "spec_helper"

RSpec.describe "Macros with methods" do
  it "calls the method with the appropriate arguments" do
    page = build_page(<<-HTML)
    <section data-id="1">
      Section 1
    </section>

    <section data-id="2">
      Section 2
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section_with_id

      def section_with_id(id:)
        "section[data-id='#{id}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section_with_id(id: 1)).to have_text("Section 1")
    expect(test_page).to have_section_with_id(id: 1)
    expect(test_page).to have_section_with_id(id: 1, text: "Section 1")
    expect(test_page).to have_section_with_id(id: 2, text: "Section 2")
    expect(test_page).to have_no_section_with_id(id: 1, text: "Section 2")
  end

  it "allows for pre-requisite calls" do
    page = build_page(<<-HTML)
    <section data-id="1">
      Section 1
    </section>

    <section data-id="2">
      Section 2
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one def section_with_id(id:)
        "section[data-id='#{id}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section_with_id(id: 1)).to have_text("Section 1")
    expect(test_page).to have_section_with_id(id: 1)
    expect(test_page).to have_section_with_id(id: 1, text: "Section 1")
    expect(test_page).to have_section_with_id(id: 2, text: "Section 2")
    expect(test_page).to have_no_section_with_id(id: 1, text: "Section 2")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
