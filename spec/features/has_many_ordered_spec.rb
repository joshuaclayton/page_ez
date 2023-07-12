require "spec_helper"

RSpec.describe "has_many_ordered", type: :feature do
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

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: :selenium_chrome_headless)
  end
end
