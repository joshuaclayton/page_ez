require "spec_helper"

RSpec.describe "Defining a macro with a method" do
  it "works as expected" do
    page = build_page(<<-HTML)
    <section data-id="1">
      Section 1
    </section>

    <section data-id="2">
      Section 2
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one def section(id:)
        "section[data-id=#{id}]"
      end
    end.new(page)

    page.visit "/"

    expect(test_page).to have_section(id: 1)
    expect(test_page).to have_section(id: 2)
    expect(test_page).to have_section(id: 2, text: "Section 2")
    expect(test_page).to have_no_section(id: 1, text: "Section 2")
  end

  it "allows for macro definition before the method is defined" do
    page = build_page(<<-HTML)
    <section data-id="1">
      Section 1
    </section>

    <section data-id="2">
      Section 2
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section

      def section(id:)
        "section[data-id=#{id}]"
      end
    end.new(page)

    page.visit "/"

    expect(test_page).to have_section(id: 1)
    expect(test_page).to have_section(id: 2)
    expect(test_page).to have_section(id: 2, text: "Section 2")
    expect(test_page).to have_no_section(id: 1, text: "Section 2")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
