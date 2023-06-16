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

    with_max_wait_time(seconds: 1) do
      # waits 1 second, then proceeds
      expect(test_page.list).not_to have_item_named("Item 2")
      # finds the element immediately, then proceeds
      expect(test_page.list).to have_item_named("Item 1")
    end

    expect(Time.now - start_time).to be_between(0.95, 1.3)

    with_max_wait_time(seconds: 1) do
      # waits ~500ms until the element is removed, then proceeds
      expect(test_page.list).to have_no_item_named("Item 1")
      # doesn't find the element and proceeds immediately
      expect(test_page.list).to have_no_item_named("Item 1")
    end

    expect(Time.now - start_time).to be_between(1.45, 1.95)
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: :selenium_chrome_headless)
  end

  def with_max_wait_time(seconds:)
    original_wait_time = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = seconds
    yield
  ensure
    Capybara.default_max_wait_time = original_wait_time
  end
end
