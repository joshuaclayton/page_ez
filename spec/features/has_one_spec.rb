require "spec_helper"

RSpec.describe "has_one", type: :feature do
  it "generates accessors returning Capybara Elements for each declared has_one" do
    page = build_page("<h1>Hello, world!</h1><p>Some description</p>")

    test_page = Class.new(PageEz::Page) do
      has_one :heading, "h1"
      has_one :description, "p"
    end.new(page)

    page.visit "/"

    expect(test_page.heading).to have_content("Hello, world!")
    expect(test_page.description).to have_content("Some description")

    expect(test_page.heading.text).to eq("Hello, world!")
    expect(test_page.description.text).to eq("Some description")

    expect(test_page.heading.tag_name).to eq("h1")
    expect(test_page.description.tag_name).to eq("p")
  end

  it "generates predicate methods for each declared has_one" do
    page = build_page("<h1>Hello, world!</h1><p>Some description</p>")
    test_page = Class.new(PageEz::Page) do
      has_one :heading, "h1"
      has_one :description, "p"
      has_one :section, "section"
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading
    expect(test_page).not_to have_no_heading

    expect(test_page).to have_description
    expect(test_page).not_to have_no_description

    expect(test_page).not_to have_section
    expect(test_page).to have_no_section
  end

  it "allows for selector nesting" do
    page = build_page(<<-HTML)
    <section>
      <h2>Section Heading</h2>
      <p>Section Description</p>
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section, "section" do
        has_one :heading, "h2"
        has_one :description, "p"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section).to have_heading
    expect(test_page.section.heading).to have_content("Section Heading")
    expect(test_page.section.description).to have_content("Section Description")
  end

  it "allows for defining methods that can access the results of has_one" do
    page = build_page(<<-HTML)
    <section>
      <h2>Section Heading</h2>
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section, "section" do
        has_one :heading, "h2"

        def heading_tag_name
          heading.tag_name
        end
      end

      def section_heading_tag_name
        section.heading_tag_name
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section.heading_tag_name).to eq("h2")
    expect(test_page.section_heading_tag_name).to eq("h2")
  end

  it "behaves as Capybara would when there's an ambiguous match" do
    page = build_page(<<-HTML)
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :item, "li"
      end
    end.new(page)

    page.visit "/"

    expect { test_page.list.item }.to raise_error(Capybara::Ambiguous)
  end

  it "allows for passing arguments to carry through to Capybara arguments" do
    page = build_page(<<-HTML)
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :item_named, "li", ->(name) { {text: name} }
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.item_named("Item 1")).to be_visible

    expect(test_page.list).to have_item_named("Item 1")
    expect(test_page.list).to have_item_named("Item 2")
    expect(test_page.list).not_to have_item_named("Item 3")
  end

  it "allows for passing constant values through to Capybara arguments" do
    page = build_page(<<-HTML)
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :first_item, "li", match: :first
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.first_item).to have_content("Item 1")
    expect(test_page.list).to have_first_item
  end

  it "allows for combining arguments and constant values" do
    page = build_page(<<-HTML)
    <ul>
      <li data-index='0'>Item 1</li>
      <li data-index='1'>Item 2</li>
      <li data-index='2'>Item 2</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :first_item_named, "li", ->(name) { {text: name} }, match: :first
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.first_item_named("Item 1")).to be_visible
    expect(test_page.list.first_item_named("Item 2")).to be_visible
    expect(test_page.list.first_item_named("Item 2")["data-index"]).to eq("1")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
