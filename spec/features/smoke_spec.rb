require "spec_helper"

RSpec.describe "Smoke spec", type: :feature do
  let(:page) do
    AppGenerator
      .new(title: "Application Title")
      .route("/", "<h1>Hello, world!</h1>")
      .run
  end

  it "is successful" do
    hello_page = Class.new(PageEz::Page) do
      has_one :heading, "h1"
    end

    visit "/"

    hello_page = hello_page.new(page)

    expect(hello_page).to have_heading
    expect(hello_page.heading.text).to eq("Hello, world!")
    expect(hello_page).to have_title("Application Title")
  end

  it "raises when incorrect methods are used immediately" do
    expect do
      Class.new(PageEz::Page) do
        has_one :dashboard, "section[data-role=cards]" do
          has_many1 :cards, "ul li"
        end
      end
    end.to raise_error(NoMethodError, /has_many1/)
  end
end
