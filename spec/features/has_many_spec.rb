require "spec_helper"

RSpec.describe "has_many", type: :feature do
  it "generates accessors returning Capybara Elements for each declared has_many" do
    page = build_page(<<-HTML)
    <ul>
      <li>
        <span data-role='todo-name'>Buy milk</span>
        <button>Done</button>
      </li>
      <li>
        <span data-role='todo-name'>Buy eggs</span>
        <button>Done</button>
      </li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many :todos, "ul li" do
        has_one :name, "span[data-role=todo-name]"
      end

      has_many :todo_names, "ul li span[data-role='todo-name']"
    end.new(page)

    page.visit "/"

    expect(test_page.todos.count).to eq(2)
    expect(test_page).to have_todo_matching(text: "Buy milk")
    expect(test_page).to have_todo_matching(text: "Buy eggs")
    expect(test_page).to have_no_todo_matching(text: "Buy yogurt")
    expect(test_page.todo_matching(text: "Buy milk")).to have_name(text: "Buy milk")
    expect(test_page.todo_matching(text: "Buy milk")).to have_button("Done")
    expect(test_page.todo_matching(text: "Buy eggs")).to have_name(text: "Buy eggs")
    expect(test_page.todo_matching(text: "Buy eggs")).to have_button("Done")
    expect(test_page.todo_matching(text: "Buy", match: :first)).to have_name(text: "Buy milk")
    expect(test_page.todo_names.map(&:text)).to eq(["Buy milk", "Buy eggs"])
  end

  it "allows for nested methods" do
    page = build_page(<<-HTML)
    <ul>
      <li>
        <span data-role='todo-name'>Buy milk</span>
        <button>Done</button>
      </li>
      <li>
        <span data-role='todo-name'>Buy eggs</span>
        <button>Done</button>
      </li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many :todos, "ul li" do
        def name_text
          find("span[data-role='todo-name']").text
        end
      end
    end.new(page)

    page.visit "/"

    expect(test_page.todos.map(&:name_text)).to eq(["Buy milk", "Buy eggs"])
  end

  it "allows for scoping arguments" do
    page = build_page(<<-HTML)
    <section>
      <h2>Section 1</h2>
    </section>
    <section>
      <h2>Section 2</h2>
    </section>
    <section>
      <h2>Third section that should not match</h2>
    </section>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many :sections, "section", ->(name) { {text: name} }
    end.new(page)

    page.visit "/"

    expect(test_page.sections("Section 1").map(&:text)).to eq(["Section 1"])
    expect(test_page.sections("Section").map(&:text)).to eq(["Section 1", "Section 2"])
    expect(test_page.sections("Bogus")).to be_empty
  end

  it "allows for checking for any or no elements" do
    page = build_page(<<-HTML)
    <div>
      <ul>
        <li>1-1</li>
        <li>1-2</li>
        <li>1-3</li>
      </ul>

      <ul>
      </ul>
    </div>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :first_list, "ul:nth-of-type(1)" do
        has_many :items, "li"
      end

      has_one :second_list, "ul:nth-of-type(2)" do
        has_many :items, "li"
      end

      has_one :third_list, "ul:nth-of-type(3)" do
        has_many :items, "li"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.first_list.items).to have_any_elements
    expect(test_page.first_list.items).not_to have_no_elements

    expect(test_page.second_list.items).not_to have_any_elements
    expect(test_page.second_list.items).to have_no_elements

    expect(test_page.first_list).to have_items
    expect(test_page.first_list).not_to have_no_items

    expect(test_page.second_list).not_to have_items
    expect(test_page.second_list).to have_no_items
  end
end
