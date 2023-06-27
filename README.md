# PageEz

PageEz is a tool to define page objects with [Capybara].

[Capybara]: https://github.com/teamcapybara/capybara

## Alpha Software - Proof of Concept

This is currently a proof of concept. The interface, name, and potentially
anything else may change vastly.

## Installation

Add the gem to your `Gemfile`:

```
gem "page_ez", git: "https://github.com/joshuaclayton/page_ez"
```

## Usage

Define a page object:

```rb
class TodosIndex < PageEz::Page
  has_one :active_list, "section.active ul" do
    has_many :items do
      has_one :name, "span[data-role=todo-name]"
      has_one :checkbox, "input[type=checkbox]"

      def mark_complete
        checkbox.click
      end
    end
  end

  def active_todo_names
    items.map { _1.name.text }
  end

  has_one :completed_list, "section.complete ul" do
    has_many :items do
      has_one :name, "span[data-role=todo-name]"
      has_one :checkbox, "input[type=checkbox]"

      def mark_incomplete
        checkbox.click
      end
    end
  end
end
```

Use your page object:

```rb
it "manages todos state when completing" do
  user = create(:user)
  create(:todo, name: "Buy milk", user:)
  create(:todo, name: "Buy eggs", user:)

  sign_in_as user

  todos_index = TodosIndex.new

  expect(todos_index.active_todo_names).to eq(["Buy milk", "Buy eggs"])
  todos_index.active_list.items.first.mark_complete
  expect(todos_index.active_todo_names).to eq(["Buy eggs"])
  todos_index.active_list.items.first.mark_complete

  expect(todos_index.active_todo_names).to be_empty

  todos_index.completed_list.items.first.mark_incomplete
  expect(todos_index.active_todo_names).to eq(["Buy milk"])
  todos_index.completed_list.items.first.mark_incomplete
  expect(todos_index.active_todo_names).to eq(["Buy milk", "Buy eggs"])
end
```

### `has_one`

You can define accessors to individual elements (matched with Capybara's `find`):

```rb
class BlogPost < PageEz::Page
  has_one :post_title, "header h2"
  has_one :body, "section[data-role=post-body]"
  has_one :published_date, "time[data-role=published-date]"
end
```

### `has_many`

You can define accessors to multiple elements (matched with Capybara's `all`):

```rb
class TodosIndex < PageEz::Page
  has_many :todos, "ul li span[data-role=todo-name]"
end
```

### `has_many_ordered`

This mirrors the `has_many` macro but adds additional methods for accessing
elements at a specific index.

```rb
class TodosIndex < PageEz::Page
  has_many_ordered :todos, "ul[data-role=todo-list] li" do
    has_one :title, "span[data-role=todo-title]"
    has_one :complete, "input[type=checkbox][data-role=mark-complete]"

    def complete?
      complete.checked?
    end
  end
end

todos_index = TodosIndex.new

expect(todos_index.todo_at(0)).to have_text("Buy milk")
# or
expect(todos_index).to have_todo_at(0, text: "Buy milk")

todos_index.todo_at(0).complete.click

expect(todos_index.todo_at(0)).to be_complete
```

While the gem is under active development and the APIs are being determined,
it's best to review the feature specs to understand how to use the gem.

## Configuration

### Logger

Configure PageEz's logger to capture debugging information about
which page objects and methods are defined.


```rb
PageEz.configure do |config|
  config.logger = Logger.new($stdout)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Feature Tests

This uses a test harness for Rack app generation called `AppGenerator`, which
handles mounting HTML responses to endpoints accessible via `GET`.

```ruby
def page
  @app ||= AppGenerator
    .new
    .route("/", "Hello, strange!")
    .route("/hello", "<h1>Hello, world!</h1>")
    .run
end
```

To run tests, either define `page` (via `def page` or RSpec's `let`) to allow
for standard Capybara interaction within tests.

## Roadmap

* [x] Verify page object interactions work within `within`
* [ ] Define `form` syntax
* [ ] Define `define` syntax (FactoryBot style)
* [ ] "Unsafe" short-circuit for verifying elements aren't present on the page (e.g. `find("selector", count: 0)`)
* [ ] Nested/reference-able page objects (from `define` syntax, by symbol, or by class name)

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/joshuaclayton/page_ez. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [code of
conduct](https://github.com/joshuaclayton/page_ez/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PageEz project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/joshuaclayton/page_ez/blob/main/CODE_OF_CONDUCT.md).
