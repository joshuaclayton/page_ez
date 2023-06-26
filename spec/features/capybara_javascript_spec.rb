require "spec_helper"

RSpec.describe "Capybara and JavaScript", type: :feature do
  it "behaves as expected when using has_css? and has_no_css?" do
    page = build_page(<<-HTML)
    <section>
      <ul>
        <li>Item 1</li>
      </ul>
    </section>
    <script type="text/javascript">
      document.addEventListener('DOMContentLoaded', () => {
        setTimeout(() => {
          document.querySelector("ul li").remove();
        }, 1500);
      });
    </script>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_one :item_named, "li", ->(name) { {text: name} }
      end
    end.new(page)

    page.visit "/"

    start_time = Time.now

    with_max_wait_time(seconds: 1.2) do
      # waits 1 second, then proceeds
      expect(test_page.list).not_to have_item_named("Item 2")
      # finds the element immediately, then proceeds
      expect(test_page.list).to have_item_named("Item 1")
    end

    expect(Time.now - start_time).to be_between(0.95, 1.7)

    with_max_wait_time(seconds: 1) do
      # waits ~500ms until the element is removed, then proceeds
      expect(test_page.list).to have_no_item_named("Item 1")
      # doesn't find the element and proceeds immediately
      expect(test_page.list).to have_no_item_named("Item 1")
    end

    expect(Time.now - start_time).to be_between(1.4, 2.7)
  end

  it "allows for counting elements while waiting" do
    page = build_page(<<-HTML)
    <template id="item">
      <li></li>
    </template>

    <section>
      <ul>
        <li>Item 1</li>
      </ul>
    </section>

    <script type="text/javascript">
      function generateItem(title, target) {
        const template = document.querySelector("template#item");
        const item = template.content.cloneNode(true);
        item.querySelector("li").textContent = title;

        target.appendChild(item);
      }

      document.addEventListener("DOMContentLoaded", () => {
        const target = document.querySelector("section ul");

        setTimeout(() => {
          generateItem("Item 2", target);
          generateItem("Item 3", target);
          generateItem("Item 4", target);
        }, 1500);
      });
    </script>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_many :items, "li"
      end
    end.new(page)

    page.visit "/"

    with_max_wait_time(seconds: 1) do
      expect(test_page.list).to have_items_count(1)
      expect(test_page.list.items.count).to eq(1)
    end

    with_max_wait_time(seconds: 2) do
      expect(test_page.list).to have_items_count(4)
    end
  end

  it "allows for more intuitive counting" do
    page = build_page(<<-HTML)
    <template id="item">
      <li></li>
    </template>

    <section>
      <ul>
        <li>Item 1</li>
      </ul>
    </section>

    <script type="text/javascript">
      function generateItem(title, target) {
        const template = document.querySelector("template#item");
        const item = template.content.cloneNode(true);
        item.querySelector("li").textContent = title;

        target.appendChild(item);
      }

      document.addEventListener("DOMContentLoaded", () => {
        const target = document.querySelector("section ul");

        setTimeout(() => {
          generateItem("Item 2", target);
          generateItem("Item 3", target);
          generateItem("Item 4", target);
        }, 1500);
      });
    </script>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_many :items, "li"
      end
    end.new(page)

    page.visit "/"

    with_max_wait_time(seconds: 1) do
      expect(test_page.list.items).to have_count_of(1)
    end

    with_max_wait_time(seconds: 2) do
      expect do
        expect(test_page.list.items.count).to eq(4)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /got: 1/)

      expect(test_page.list.items).to have_count_of(4)
    end
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: :selenium_chrome_headless)
  end
end
