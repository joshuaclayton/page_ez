require "spec_helper"

RSpec.describe "Selectors" do
  it "allows string selectors" do
    page = build_page(<<-HTML)
    <h1>Hello</h1>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :heading, "h1"
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading
  end

  it "allows symbol selectors" do
    page = build_page(<<-HTML)
    <h1>Hello</h1>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :heading, :h1
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading
  end

  it "allows symbol selectors with dynamic options" do
    page = build_page(<<-HTML)
    <h1>Hello</h1>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :heading, :h1, ->(name) { {text: name} }
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading("Hello")
    expect(test_page).not_to have_heading("Bogus")
  end

  it "uses the element name as a selector when one isn't given" do
    page = build_page(<<-HTML)
    <heading>Hello</heading>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :heading
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
