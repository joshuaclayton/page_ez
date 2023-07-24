require "spec_helper"

RSpec.describe "has_many_ordered", type: :feature do
  it "allows for nested elements with the same name" do
    page = build_page(<<-HTML)
    <main>
      <header>
        <h2>Received Webhooks</h2>
      </header>
      <section>
        <ul data-role="webhooks-list">
          <li>
            <div data-role="webhook-header">
              <div>
                <div data-role="webhook-source">Recurly</div>
              </div>
            </div>
          </li>
          <li>
            <div data-role="webhook-header">
              <div>
                <div data-role="webhook-source">Google</div>
              </div>
            </div>
          </li>
        </ul>
      </section>
    </main>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :header do
        has_one :heading, "h2"
      end

      has_many_ordered :webhooks, "ul[data-role=webhooks-list] li" do
        # has_one :webhook_header, "div[data-role=webhook-header]" do
        has_one :header, "div[data-role=webhook-header]" do
          has_one :source, "div[data-role=webhook-source]"
        end
      end
    end.new(page)

    page.visit "/"

    expect(test_page).to have_header
    expect(test_page.header).to have_heading(text: "Received Webhooks")
    expect(test_page.webhook_at(0)).to have_header
    # expect(test_page.webhook_at(0)).to have_webhook_header
    expect(test_page.webhook_at(0).header).to have_source
    # expect(test_page.webhook_at(0).webhook_header).to have_source
  end

  it "allows for selection at an index" do
    page = build_page(<<-HTML)
    <template id="item">
      <li>
        <span data-role="title"></span>
        <input type="checkbox" name="complete" />
      </li>
    </template>

    <section>
      <ul>
        <li>
          <span data-role="title">Item 1</span>
          <input type="checkbox" name="complete" />
        </li>
      </ul>
    </section>

    <script type="text/javascript">
      function generateItem(title, target) {
        const template = document.querySelector("template#item");
        const item = template.content.cloneNode(true);
        item.querySelector("span[data-role=title]").textContent = title;

        target.appendChild(item);
      }

      document.addEventListener("DOMContentLoaded", () => {
        const target = document.querySelector("section ul");

        setTimeout(() => {
          generateItem("Item 2", target);
          generateItem("Item 3", target);
          generateItem("Item 4", target);
        }, 250);
      });
    </script>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "section ul" do
        has_many_ordered :items, "li" do
          has_one :item_title, "span[data-role=title]"
        end
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list.items[0]).not_to be_nil

    expect(test_page.list.items[1]).to be_nil
    expect(test_page.list.items[2]).to be_nil
    expect(test_page.list.items[3]).to be_nil

    page.visit "/"

    expect(test_page.list.item_at(0)).to have_content("Item 1")
    expect(test_page.list.item_at(1)).to have_content("Item 2")
    expect(test_page.list.item_at(2)).to have_content("Item 3")
    expect(test_page.list.item_at(3)).to have_content("Item 4")

    page.visit "/"

    expect(test_page.list.item_at(0).item_title).to have_text("Item 1")
    expect(test_page.list.item_at(1).item_title).to have_text("Item 2")
    expect(test_page.list.item_at(2).item_title).to have_text("Item 3")
    expect(test_page.list.item_at(3).item_title).to have_text("Item 4")

    page.visit "/"

    expect(test_page.list).to have_item_at(0, text: "Item 1")
    expect(test_page.list).to have_item_at(1, text: "Item 2")
    expect(test_page.list).to have_item_at(2, text: "Item 3")
    expect(test_page.list).to have_item_at(3, text: "Item 4")

    page.visit "/"

    expect(test_page.list).to have_items_count(4)

    expect do
      test_page.list.item_at(4)
    end.to raise_error(Capybara::ElementNotFound)

    page.visit "/"

    with_max_wait_time(seconds: 0.1) do
      expect(test_page.list.item_at(2, wait: 1).item_title).to have_text("Item 3")
    end
  end

  it "allows for dynamic options" do
    page = build_page(<<-HTML)
    <ul>
      <li>List of 3 Items</li>
      <li>2nd item</li>
      <li>3rd item</li>
    </ul>

    <ul>
      <li>List of 3 Items</li>
      <li>2nd item</li>
      <li>3rd item</li>
    </ul>

    <ul>
      <li>List of 2 Items</li>
      <li>2nd item</li>
    </ul>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_many_ordered :lists, "ul", ->(name:) { {text: name} } do
        has_many :items, "li"
      end
    end.new(page)

    page.visit "/"

    expect(test_page.list_at(0, name: "List of 3 Items").items).to have_count_of(3)
    expect(test_page.list_at(1, name: "List of 3 Items").items).to have_count_of(3)
    expect(test_page.list_at(2, name: "List of 2 Items").items).to have_count_of(2)
    expect(test_page).not_to have_list_at(2, name: "List of 3 Items")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: :selenium_chrome_headless)
  end
end
