require "spec_helper"

RSpec.describe "Shorthand define syntax", type: :feature do
  it "allows for definition of page objects" do
    po_module = Module.new do
      include PageEz::Definer
    end

    po_module.define do
      page(:test) do
        has_one :heading, "heading" do
          has_one :title, "h1"
          has_one :nav, "nav" do
            has_many :links, "a"
          end
        end
      end
    end

    page = build_page(<<-HTML)
    <heading>
      <h1>Test</h1>
      <nav>
        <a href="/">Home</a>
      </nav>
    </heading>
    HTML

    test_page = po_module.page(:test).new(page)

    page.visit("/")

    expect(test_page).to have_heading
    expect(test_page.heading.nav.links.first.text).to eq("Home")
  end

  it "raises when two page objects are defined in the same module" do
    po_module = Module.new do
      include PageEz::Definer
    end

    expect do
      po_module.define do
        page(:test) do
        end

        page(:test) do
        end
      end
    end.to raise_error(PageEz::Definer::DuplicateDefinitionError, "Already defined page object: test")
  end

  it "allows for multiple namespaces to define the same page object" do
    po_module = Module.new do
      include PageEz::Definer
    end

    different_po_module = Module.new do
      include PageEz::Definer
    end

    expect do
      po_module.define do
        page(:test) do
          has_one :heading, "heading[data-role='in-po-module']"
        end
      end

      different_po_module.define do
        page(:test) do
          has_one :heading, "heading[data-role='in-different-po-module']"
        end
      end
    end.not_to raise_error

    page = build_page(<<-HTML)
    <heading data-role="in-po-module">In PO Module</heading>
    <heading data-role="in-different-po-module">In Different PO Module</heading>
    HTML

    in_po_module_page = po_module.page(:test).new(page)
    in_different_po_module_page = different_po_module.page(:test).new(page)

    page.visit("/")

    expect(in_po_module_page.heading.text).to eq("In PO Module")
    expect(in_different_po_module_page.heading.text).to eq("In Different PO Module")
  end

  it "raises if the page object is not defined" do
    PoModule = Module.new do # rubocop:disable Lint/ConstantDefinitionInBlock
      include PageEz::Definer
    end

    expect do
      PoModule.page(:undefined).new
    end.to raise_error(PageEz::Definer::NoDefinitions, "No page object definitions found in PoModule")

    other_po_module = Module.new do
      include PageEz::Definer
    end

    other_po_module.define do
      page(:test)
    end

    expect do
      other_po_module.page(:undefined).new
    end.to raise_error(PageEz::Definer::MissingDefinition, "No definition found for page object: undefined")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run
  end
end
