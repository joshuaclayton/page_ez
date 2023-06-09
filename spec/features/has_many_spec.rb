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
      has_many :todos, "ul li"
      has_many :todo_names, "ul li span[data-role='todo-name']"
    end.new(page)

    page.visit "/"

    expect(test_page.todos.count).to eq(2)
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

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
