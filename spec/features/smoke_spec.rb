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

    expect(hello_page.has_heading?).to be true
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

  it "raises when multiple macros are declared with the same name" do
    expect do
      Class.new(PageEz::Page) do
        has_one :list, "ul"
        has_many :list, "ul li"
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /list/)

    expect do
      Class.new(PageEz::Page) do
        has_one :heading
        has_one :heading
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /heading/)

    expect do
      Class.new(PageEz::Page) do
        has_one :heading, "heading" do
          has_many :list_items, "li"
          has_many :list_items, "li"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /list_items/)
  end

  it "raises when a macro is run against a symbol and then a method is defined again" do
    expect do
      Class.new(PageEz::Page) do
        has_one def thing
          "heading"
        end

        def thing
          "h1"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /thing/)
  end

  it "raises when a macro is run against a symbol and then a method is defined again in a nested context" do
    expect do
      Class.new(PageEz::Page) do
        has_one :parent do
          has_one def thing
            "h2"
          end

          def thing
            "overridden"
          end
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /thing/)
  end

  it "raises when a macro is run against a static selector and then a method is defined again" do
    expect do
      Class.new(PageEz::Page) do
        has_one :thing, "h3"

        def thing
          "overridden"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError, /thing/)
  end

  it "allows nested macros to share the same name" do
    expect do
      Class.new(PageEz::Page) do
        has_one :heading, "heading" do
          has_one :heading, "h3"
        end
      end
    end.not_to raise_error

    expect do
      Class.new(PageEz::Page) do
        has_one :first_section, "section.first" do
          has_one :heading
        end

        has_one :second_section, "section.second" do
          has_one :heading
        end
      end
    end.not_to raise_error

    expect do
      Class.new(PageEz::Page) do
        has_one :parent do
          has_one :thing

          def thing
            "h3"
          end
        end
      end
    end.not_to raise_error

    expect do
      Class.new(PageEz::Page) do
        has_one :thing

        def thing
          "h3"
        end
      end
    end.not_to raise_error
  end

  it "allows for macros across PageEz::Page subclasses to refer to the same name" do
    expect do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      class ComposedPage < PageEz::Page
      end

      class BasePage < PageEz::Page
      end

      class OtherPageWithComposed < PageEz::Page
        has_one :composed_page, "section.composed"
      end

      class PageWithComposed < BasePage
        has_one :composed_page, ComposedPage
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
    end.not_to raise_error
  end

  it "allows for inheritance where macros do not collide" do
    expect do
      composed_page = Class.new(PageEz::Page) do
        has_one :nested, "section" do
        end
      end

      Class.new(PageEz::Page) do
        has_one :list, "ul"
      end

      Class.new(composed_page) do
        has_one :list, "ul"
      end
    end.not_to raise_error
  end
end
