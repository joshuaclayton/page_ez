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
        def card
          Card.new(self)
        end
      end

      def primary_nav
        PrimaryNav.new(find("nav.primary"))
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    visit "/"

    dashboard = Dashboard.new

    expect(dashboard.primary_nav).to have_home_link
    expect(dashboard.metrics.size).to eq(3)
    expect(dashboard.metric_at(0).card.header).to have_text("Metric 0")
  end

  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run.tap do |session|
        # this simulates more standard Rails testing behavior, where a `page`
        # isn't assigned to explicitly.
        allow(Capybara).to receive(:current_session).and_return(session)
      end
  end
end
