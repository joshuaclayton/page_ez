require "spec_helper"

RSpec.describe "Page object composition", type: :feature do
  it "works as expected with correct nesting" do
    build_page(<<-HTML)
    <nav class="primary">
      <ul>
        <li><a data-role="home-link" href="/">Home</a></li>
      </ul>
    </nav>

    <ul class="metrics">
      <li><h3>Metric 0</h3></li>
      <li><h3>Metric 1</h3></li>
      <li><h3>Metric 2</h3></li>
    </ul>

    <ul class="stats">
      <li><h3>Stat 1</h3></li>
      <li><h3>Stat 2</h3></li>
      <li><h3>Stat 3</h3></li>
    </ul>

    <footer>
      <a data-role="home-link" href="/">Home</a>
    </footer>
    HTML

    # rubocop:disable Lint/ConstantDefinitionInBlock
    class Card < PageEz::Page
      has_one :header, "h3"
    end

    class PrimaryNav < PageEz::Page
      has_one :home_link, "a[data-role='home-link']"
    end

    class Dashboard < PageEz::Page
      has_many_ordered :metrics, "ul.metrics li" do
        has_one :card, Card
      end

      has_one :primary_nav, PrimaryNav, base_selector: "nav.primary" do
        has_one :other_thing, "a"

        def awesome?
          true
        end
      end

      has_one :footer_nav, PrimaryNav, base_selector: "footer"
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    visit "/"

    dashboard = Dashboard.new

    expect do
      dashboard.primary_nav.home_link
    end.not_to raise_error

    expect(dashboard).to have_primary_nav
    expect(dashboard.primary_nav).to be_awesome
    expect(dashboard.primary_nav).to have_text("Home")
    expect(dashboard.primary_nav.other_thing).to have_text("Home")
    expect(dashboard.footer_nav).not_to respond_to(:awesome?)
    expect(dashboard.metrics.size).to eq(3)
    expect(dashboard.metric_at(0).card.header).to have_text("Metric 0")
    expect(dashboard.metric_at(0).card).to have_header(text: "Metric 0")
  end

  def build_page(markup)
    super(markup).tap do |session|
      # this simulates more standard Rails testing behavior, where a `page`
      # isn't assigned to explicitly.
      allow(Capybara).to receive(:current_session).and_return(session)
    end
  end
end
