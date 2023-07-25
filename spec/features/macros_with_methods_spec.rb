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

  it "allows for use with has_many_ordered" do
    page = build_page(<<-HTML)
    <ul>
      <li data-state="complete">
        <input type="checkbox" name="todos[1]" data-action="mark-incomplete" checked>
        <span data-role="title">Buy milk</span>
      </li>
      <li data-state="incomplete">
        <input type="checkbox" name="todos[2]" data-action="mark-complete">
        <span data-role="title">Buy eggs</span>
      </li>
      <li data-state="incomplete">
        <input type="checkbox" name="todos[3]" data-action="mark-complete">
        <span data-role="title">Buy onions</span>
      </li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many_ordered :items do
        has_one :name, "[data-role='title']"
        has_one :checkbox, "input[type='checkbox']"
      end

      def items(state:)
        "li[data-state='#{state}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.items(state: "complete")).to have_count_of(1)
    expect(test_page.items(state: "incomplete")).to have_count_of(2)
    expect(test_page).to have_item_at(0, state: "complete")
    expect(test_page).not_to have_item_at(1, state: "complete")
    expect(test_page).to have_item_at(0, state: "incomplete")
    expect(test_page).to have_item_at(1, state: "incomplete")
    expect(test_page).not_to have_item_at(2, state: "incomplete")
    expect(test_page.item_at(0, state: "complete")).to have_name(text: "Buy milk")
    expect(test_page.item_at(0, state: "complete").checkbox).to be_checked
    expect(test_page.item_at(0, state: "incomplete")).to have_name(text: "Buy eggs")
    expect(test_page.item_at(1, state: "incomplete")).to have_name(text: "Buy onions")
  end

  it "allows for use with has_many" do
    page = build_page(<<-HTML)
    <ul>
      <li data-state="complete">
        <input type="checkbox" name="todos[1]" data-action="mark-incomplete" checked>
        <span data-role="title">Buy milk</span>
      </li>
      <li data-state="incomplete">
        <input type="checkbox" name="todos[2]" data-action="mark-complete">
        <span data-role="title">Buy eggs</span>
      </li>
      <li data-state="incomplete">
        <input type="checkbox" name="todos[3]" data-action="mark-complete">
        <span data-role="title">Buy onions</span>
      </li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many :items do
        has_one :name, "[data-role='title']"
        has_one :checkbox, "input[type='checkbox']"
      end

      def items(state:)
        "li[data-state='#{state}']"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.items(state: "complete")).to have_count_of(1)
    expect(test_page.items(state: "incomplete")).to have_count_of(2)
    expect(test_page.items(state: "complete").first.name).to have_text("Buy milk")
    expect(test_page.items(state: "incomplete").first.name).to have_text("Buy eggs")
    expect(test_page.items(state: "incomplete")[1].name).to have_text("Buy onions")
  end
end
