require "spec_helper"

RSpec.describe "Extending PageEz::Page", type: :feature do
  it "works with Ruby things" do
    page = build_page(<<-HTML)
    <section data-role="my-awesome-section">
      <div data-role="element-with-dynamic" data-id="124">Content</div>
      <div data-role="element-with-dynamic" data-id="124">Other</div>
      <div data-role="my-awesome-thing" data-id="124">Content</div>
      <div data-object="Todo" data-id="4">Buy Milk</div>
    </section>
    HTML

    PageEz.configure do |config|
      config.register_selector(:by_data_role) do |name|
        "[data-role='#{name.to_s.dasherize}']"
      end

      config.register_selector(:by_data_id) do |name, id:|
        "[data-role='#{name.to_s.dasherize}'][data-id='#{id}']"
      end

      config.register_selector(:by_object) do |type:, id:|
        "[data-object='#{type}'][data-id='#{id}']"
      end
    end

    test_page = Class.new(PageEz::Page) do
      has_one :my_awesome_section, :by_data_role
      has_one :my_awesome_thing, :by_data_id
      has_one :element_by_object, :by_object
      has_one :element_with_dynamic, :by_data_id, ->(name:) { {text: name} }
    end.new(page)

    page.visit "/"

    expect(test_page).to have_my_awesome_section

    start_time = Time.now

    expect(test_page).to have_my_awesome_thing(id: "124")
    expect(test_page).to have_element_by_object(type: "Todo", id: 4)
    expect(test_page).to have_element_with_dynamic(id: 124, name: "Content")
    expect(test_page).to have_element_with_dynamic(id: 124, name: "Other")
    expect(test_page).not_to have_element_with_dynamic(id: 123, name: "Content")
    expect(test_page).not_to have_my_awesome_thing(id: "123", wait: 1)

    expect(Time.now - start_time).to be >= 0.8
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: :selenium_chrome_headless)
  end
end
