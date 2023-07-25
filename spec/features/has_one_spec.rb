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
    expect(test_page.section).to have_description
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

        def named?(name)
          heading.has_text?(name)
        end
      end

      def section_heading_tag_name
        section.heading_tag_name
      end
    end.new(page)

    page.visit "/"

    expect(test_page.section.heading_tag_name).to eq("h2")
    expect(test_page.section_heading_tag_name).to eq("h2")
    expect(test_page.section).to be_named("Section Heading")
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

  it "allows for passing positional arguments to carry through to Capybara arguments" do
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

  it "allows for passing keyword arguments to carry through to Capybara arguments" do
    page = build_page(<<-HTML)
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :item_named, "li", ->(name:) { {text: name} }
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.item_named(name: "Item 1")).to be_visible

    expect(test_page.list).to have_item_named(name: "Item 1")
    expect(test_page.list).to have_item_named(name: "Item 2")
    expect(test_page.list).not_to have_item_named(name: "Item 3")
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
        has_one :first_item_passed_name, "li", ->(name:) { {text: name} }, match: :first
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.first_item_named("Item 1")).to be_visible
    expect(test_page.list.first_item_named("Item 2")).to be_visible
    expect(test_page.list.first_item_named("Item 2")["data-index"]).to eq("1")

    expect(test_page.list).to have_no_first_item_passed_name(name: "Item 1", text: "Bogus")
    expect(test_page.list).to have_first_item_passed_name(name: "Wrong but will be overridden", text: "Item 1")
  end

  it "allows for using `within` to scope selectors" do
    page = build_page(<<-HTML)
    <section class="empty">
    </section>

    <section class="list-with-no-lis">
      <ul>
      </ul>
    </section>

    <section class="list-with-lis">
      <ul>
        <li>Item 1</li>
        <li>Item 2</li>
      </ul>
    </section>

    <section class="second-list-with-lis">
      <ul>
        <li>Item 1</li>
      </ul>
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :item_named, "li", ->(name) { {text: name} }
      end
    end.new(page)

    page.visit "/"

    page.within "section.empty" do
      expect(test_page).not_to have_list
    end

    page.within "section.list-with-no-lis" do
      expect(test_page).to have_list
      expect(test_page.list).not_to have_css("li")
    end

    page.within "section.list-with-lis" do
      expect(test_page.list).to have_css("li", count: 2)
      expect(test_page.list).to have_item_named("Item 1")
      expect(test_page.list).to have_item_named("Item 2")
    end

    page.within "section.second-list-with-lis" do
      expect(test_page.list).to have_item_named("Item 1")
      expect(test_page.list).not_to have_item_named("Item 2")
    end
  end

  it "allows for interacting with forms" do
    page = build_page(<<-HTML)
    <form>
      <input name="name" type="text" />
      <input name="email" type="text" />
    </form>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :form, "form" do
        has_one :name_field, "input[name=name]"
        has_one :email_field, "input[name=email]"
      end
    end.new(page)

    page.visit "/"

    test_page.form.name_field.fill_in with: "Awesome Person"
    test_page.form.email_field.fill_in with: "person@example.com"

    expect(test_page.form.name_field.value).to eq "Awesome Person"
    expect(test_page.form.email_field.value).to eq "person@example.com"
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
