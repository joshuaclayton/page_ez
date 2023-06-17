require "spec_helper"

RSpec.describe "Arguments" do
  it "allows for different types of arguments" do
    page = build_page(<<-HTML)
    <h1>Hello</h1>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :heading, "h1"
      has_one :heading_with_required_arg, "h1", ->(text) { {text: text} }
      has_one :heading_with_optional_arg, "h1", ->(text = "Hello") { {text: text} }
      has_one :heading_with_required_kwarg, "h1", ->(text:) { {text: text} }
      has_one :heading_with_optional_kwarg, "h1", ->(text: "Hello") { {text: text} }
      has_one :heading_with_required_arg_and_kwarg, "h1", ->(text, visible:) { {text: text, visible: visible} }
      has_one :heading_with_required_args_and_kwarg, "h1", ->(text, count, visible:) { {text: text, count: count, visible: visible} }
      has_one :heading_with_hash_arg, "h1", ->(options) { {text: options[:text]} }
    end.new(page)

    page.visit "/"

    expect(test_page).to have_heading
    expect(test_page).to have_heading_with_required_arg("Hello")
    expect(test_page).to have_heading_with_optional_arg
    expect(test_page).not_to have_heading_with_optional_arg("Bogus")
    expect(test_page).to have_heading_with_required_kwarg(text: "Hello")
    expect(test_page).to have_heading_with_optional_kwarg
    expect(test_page).not_to have_heading_with_optional_kwarg(text: "Bogus")
    expect(test_page).to have_heading_with_required_arg_and_kwarg("Hello", visible: true)
    expect(test_page).to have_heading_with_required_args_and_kwarg("Hello", 1, visible: true)
    expect(test_page).not_to have_heading_with_required_args_and_kwarg("Hello", 2, visible: true)
    expect(test_page).to have_heading_with_hash_arg(text: "Hello")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
