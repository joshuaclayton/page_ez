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
