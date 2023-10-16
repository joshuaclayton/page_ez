require "spec_helper"

RSpec.describe "contains" do
  it "pulls in everything from the corresponding PageEz::Page" do
    page = build_page(<<-HTML)
    <heading data-role="primary">
      <h1>Application Title</h1>
    </heading>
    <main>
      <h2>Awesome Site</h2>
    </main>
    <footer data-role="primary">
      <p data-role=copyright>Copyright 2023 Company Name</p>
    </footer>
    HTML

    heading = Class.new(PageEz::Page) do
      base_selector "heading[data-role=primary]"

      has_one :application_title, "h1"
    end

    footer = Class.new(PageEz::Page) do
      base_selector "footer[data-role=primary]"

      has_one :copyright, "p[data-role=copyright]"

      def awesome?
        true
      end
    end

    test_page = Class.new(PageEz::Page) do
      contains heading
      contains footer

      has_one :main do
        has_one :heading, "h2"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.application_title).to have_text("Application Title")
    expect(test_page).to have_application_title(text: "Application Title")

    expect(test_page.main).to have_heading(text: "Awesome Site")
    expect(test_page).to have_copyright(text: "Copyright 2023 Company Name")
    expect(test_page).to be_awesome
  end

  it "correctly stops base selector propagation within page hierarchy" do
    page = build_page(<<-HTML)
    <table data-role=test-me>
      <tbody>
        <tr>
          <td>1</td>
          <td class="one"><span>2</span></td>
        </tr>
      </tbody>
    </table>

    <table>
      <tbody>
        <tr>
          <td>1</td>
          <td>2</td>
        </tr>

        <tr>
          <td>1</td>
          <td>2</td>
        </tr>
      </tbody>
    </table>
    HTML

    table = Class.new(PageEz::Page) do
      base_selector "table[data-role=test-me]"

      has_many_ordered :rows, "tbody tr" do
        has_many :cells, "td"
      end

      has_many_ordered :other_rows, "tbody tr" do
        base_selector ".one"

        has_many :spans, "span"
      end

      has_many_ordered :broken_rows, "tbody tr" do
        base_selector "bogus"

        has_many :spans, "span"
      end
    end.new(page)

    page.visit "/"

    expect(table.rows.count).to eq(1)
    expect(table.row_at(0).cells.count).to eq(2)

    expect(table.other_rows.count).to eq(1)
    expect(table.other_row_at(0).spans.count).to eq(1)

    expect(table.broken_rows.count).to eq(1)
    expect do
      table.broken_row_at(0).spans.count
    end.to raise_error(Capybara::ElementNotFound)
  end

  it "allows multiple page objects to use contains with the same page object" do
    expect do
      heading = Class.new(PageEz::Page) do
        has_one :header
      end

      Class.new(PageEz::Page) do
        contains heading
      end

      Class.new(PageEz::Page) do
        contains heading
      end
    end.not_to raise_error
  end

  it "allows for delegating only a subset of methods" do
    page = build_page(<<-HTML)
    <heading data-role="primary">
      <h1>Application Title</h1>
    </heading>
    <main>
      <h2>Awesome Site</h2>
    </main>
    <footer data-role="primary">
      <p data-role=copyright>Copyright 2023 Company Name</p>
    </footer>
    HTML

    footer = Class.new(PageEz::Page) do
      base_selector "footer[data-role=primary]"

      has_one :copyright, "p[data-role=copyright]"

      def awesome?
        true
      end
    end

    test_page = Class.new(PageEz::Page) do
      contains footer, only: %i[has_copyright?]

      def awesome?
        false
      end
    end.new(page)

    page.visit "/"

    expect(test_page).to have_copyright(text: "Copyright 2023 Company Name")
    expect(test_page).not_to be_awesome
  end

  it "applies base selectors to contained pages" do
    page = build_page(<<-HTML)
    <ul data-role="complete-todos">
      <li data-role="todo">
        <span data-role="name">Buy milk</span>
        <button data-role="toggle-complete">Mark Incomplete</button>
      </li>
    </ul>
    <ul data-role="incomplete-todos">
      <li data-role="todo">
        <span data-role="name">Buy eggs</span>
        <button data-role="toggle-complete">Mark Complete</button>
      </li>
    </ul>
    HTML

    todo_list = Class.new(PageEz::Page) do
      has_many_ordered :items, "li[data-role=todo]" do
        has_one :name, "span[data-role=name]"
        has_one :toggle_complete_button, "[data-role=toggle-complete]"
      end
    end

    complete_todos = Class.new(PageEz::Page) do
      base_selector "ul[data-role=complete-todos]"

      contains todo_list
    end.new(page)

    incomplete_todos = Class.new(PageEz::Page) do
      base_selector "ul[data-role=incomplete-todos]"

      contains todo_list
    end.new(page)

    page.visit "/"

    expect(complete_todos.item_at(0)).to have_name(text: "Buy milk")
    expect(complete_todos.item_at(0)).to have_toggle_complete_button(text: "Mark Incomplete")

    expect(incomplete_todos.item_at(0)).to have_name(text: "Buy eggs")
    expect(incomplete_todos.item_at(0)).to have_toggle_complete_button(text: "Mark Complete")
  end

  it "raises when macros collide" do
    nav = Class.new(PageEz::Page) do
      has_many :links, "a"
    end

    expect do
      Class.new(PageEz::Page) do
        contains nav

        has_many :links, "li a"
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        has_many :links, "li a"

        contains nav
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)
  end

  it "raises when instance methods collide" do
    nav = Class.new(PageEz::Page) do
      def awesome?
        true
      end
    end

    expect do
      Class.new(PageEz::Page) do
        contains nav

        def awesome?
          false
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        def awesome?
          false
        end

        contains nav
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)
  end

  it "raises when instance methods collide with element names" do
    nav = Class.new(PageEz::Page) do
      has_many :links, "a"
    end

    expect do
      Class.new(PageEz::Page) do
        contains nav

        def links
          "whoops"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        def links
          "whoops"
        end

        contains nav
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)
  end

  it "does not raise when instance methods collide with element names in nested pages" do
    nav = Class.new(PageEz::Page) do
      has_many :links, "a"
    end

    expect do
      Class.new(PageEz::Page) do
        contains nav

        has_one :header do
          has_many :links, "a"
        end
      end
    end.not_to raise_error
  end

  it "raises NoMethodError when attempting to contains->delegate a method that does not exist" do
    footer = Class.new(PageEz::Page)

    expect do
      Class.new(PageEz::Page) do
        contains footer, only: %i[bogus]
      end
    end.to raise_error(NoMethodError, /Attempting to delegate.*to #{footer}: bogus/)
  end
end
