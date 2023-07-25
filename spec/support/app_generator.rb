class AppGenerator
  def initialize(title: "PageEz")
    @app = Class.new(Sinatra::Base)
    @title = title
  end

  def route(path, content)
    layout = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>#{title}</title>
        </head>
        <body>
          <%= yield %>
        </body>
      </html>
    HTML

    app.get path do
      erb content, layout: layout
    end

    self
  end

  def run(runner: :rack_test)
    Capybara::Session.new(runner, app)
  end

  private

  attr_reader :app, :title
end

module BuildPage
  def build_page(markup)
    AppGenerator
      .new
      .route("/", markup)
      .run(runner: @app_runner)
  end
end

RSpec.configure do |config|
  include BuildPage

  config.around do |example|
    @app_runner = (!!example.metadata[:js]) ? :selenium_chrome_headless : :rack_test

    example.run
  end
end
