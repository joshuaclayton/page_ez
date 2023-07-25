require "spec_helper"

RSpec.describe "Form interactions", type: :feature do
  it "works with selects" do
    page = build_page(<<-HTML)
    <form>
      <select id="options">
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
    </form>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :form, "form" do
        has_one :options, "select#options"

        def select_thing(value)
          select value, from: "options"
        end
      end
    end.new(page)

    page.visit "/"

    test_page.form.select_thing("One")
    test_page.form.select_thing("Two")
  end
end
