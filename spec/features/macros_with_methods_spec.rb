require "spec_helper"

RSpec.describe "Macros with methods" do
  it "calls the method with the appropriate arguments" do
    page = build_page(<<-HTML)
    <section data-id="1">
      <heading>Section 1</heading>
    </section>

    <section data-id="2">
      <heading>Section 2</heading>
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section_with_id do
        has_one :heading
      end

      def section_with_id(id:)
        "section[data-id='#{id}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section_with_id(id: 1)).to have_text("Section 1")
    expect(test_page.section_with_id(id: 1)).to have_heading
    expect(test_page.section_with_id(id: 1)).to have_heading(text: "Section 1")
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

  it "allows for more complicated argument structures" do
    page = build_page(<<-HTML)
    <section data-id="1">
      Section 1
    </section>

    <div data-id="2">
      Div 2
    </div>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one def element_with_id(element, id:)
        "#{element}[data-id='#{id}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.element_with_id("section", id: 1)).to have_text("Section 1")
    expect(test_page).to have_element_with_id("section", id: 1)
    expect(test_page).to have_element_with_id("section", id: 1, text: "Section 1")
    expect(test_page).to have_element_with_id("div", id: 2, text: "Div 2")
    expect(test_page).to have_no_element_with_id("div", id: 1, text: "Section 1")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
