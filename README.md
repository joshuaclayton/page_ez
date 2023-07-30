# PageEz

[![Coverage Status](https://coveralls.io/repos/github/joshuaclayton/page_ez/badge.svg?branch=main)](https://coveralls.io/github/joshuaclayton/page_ez?branch=main)

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
  todos_index.active_list.item_matching(text: "Buy milk").mark_complete
  expect(todos_index.active_todo_names).to eq(["Buy eggs"])
  todos_index.active_list.item_matching(text: "Buy eggs").mark_complete

  expect(todos_index.active_todo_names).to be_empty

  todos_index.completed_list.item_matching(text: "Buy milk").mark_incomplete
  expect(todos_index.active_todo_names).to eq(["Buy milk"])
  todos_index.completed_list.item_matching(text: "Buy eggs").mark_incomplete
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
    has_one :todo_title, "span[data-role=todo-title]"
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

### Using Methods as Dynamic Selectors

In the examples above, the CSS selectors are static.

However, there are a few different ways to define `has_one`, `has_many`, and
`has_many_ordered` elements as dynamic.

```rb
class TodosIndex < PageEz::Page
  has_one :todo_by_id

  def todo_by_id(id:)
    "[data-model=todo][data-model-id=#{id}]"
  end
end
```

The first mechanism declares the `has_one :todo_by_id` at the top of the file,
and the definition for the selector later on. This allows for grouping multiple
`has_one`s together for readability.

The second approach syntactically mirrors Ruby's `private_class_method`:

```rb
class TodosIndex < PageEz::Page
  has_one def todo_by_id(id:)
    "[data-model=todo][data-model-id=#{id}]"
  end

  # or

  def todo_by_id(id:)
    "[data-model=todo][data-model-id=#{id}]"
  end
  has_one :todo_by_id
end
```

In either case, the method needs to return a CSS string. PageEz will generate
the corresponding predicate methods as expected, as well (in the example above,
`#has_todo_by_id?(id:)` and `#has_no_todo_by_id?(id:)`

For the additional methods generated with the `has_many_ordered` macro (e.g.
for `has_many_ordered :items`, the methods `#item_at` and `#has_item_at?`), the
first argument is the index of the element, and all other args will be passed
through.

```rb
class TodosList < PageEz::Page
  has_many_ordered :items do
    has_one :name, "[data-role='title']"
    has_one :checkbox, "input[type='checkbox']"
  end

  def items(state:)
    "li[data-state='#{state}']"
  end
end
```

This would enable usage as follows:

```rb
todos = TodosList.new

expect(todos.items(state: "complete")).to have_count_of(1)
expect(todos.items(state: "incomplete")).to have_count_of(2)

expect(todos).to have_item_at(0, state: "complete")
expect(todos).not_to have_item_at(1, state: "complete")
expect(todos).to have_item_at(0, state: "incomplete")
expect(todos).to have_item_at(1, state: "incomplete")
expect(todos).not_to have_item_at(2, state: "incomplete")
```

While the gem is under active development and the APIs are being determined,
it's best to review the feature specs to understand how to use the gem.

## Page Object Composition

Because page objects can encompass as much or as little of the DOM as desired,
it's possible to compose multiple page objects.

### Composition via DSL

```rb
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

  has_one :primary_nav, PrimaryNav, base_selector: "nav.primary"
end
```

### Manual Composition

```rb
class Card < PageEz::Page
  has_one :header, "h3"
end

class PrimaryNav < PageEz::Page
  has_one :home_link, "a[data-role='home-link']"
end

class Dashboard < PageEz::Page
  has_many_ordered :metrics, "ul.metrics li" do
    def card
      # passing `self` is required to scope the query for the specific card
      # within the metric when nested inside `has_one`, `has_many`, and
      # `has_many_ordered`
      Card.new(self)
    end
  end

  def primary_nav
    # pass the element `Capybara::Node::Element` to scope page interaction when
    # composing at the top-level PageEz::Page class
    PrimaryNav.new(find("nav.primary"))
  end
end
```

With the following markup:

```html
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
```

One could then interact with the card as such:

```rb
# within a spec file

visit "/"

dashboard = Dashboard.new

expect(dashboard.primary_nav).to have_home_link
expect(dashboard.metric_at(0).card.header).to have_text("Metric 0")
```

Review page object composition within the [composition specs].

[composition specs]: ./spec/features/composition_spec.rb

## Configuration

### Logger

Configure PageEz's logger to capture debugging information about
which page objects and methods are defined.


```rb
PageEz.configure do |config|
  config.logger = Logger.new($stdout)
end
```

### Pluralization Warnings

Use of the different macros imply singular or plural values, e.g.

* `has_one :todos_list, "ul"`
* `has_many :cards, "li[data-role=card]"`

By default, PageEz allows for any pluralization usage regardless of macro. You
can configure PageEz to either warn (via its logger) or raise an exception if
pluralization doesn't look to align. Behind the scenes, PageEz uses
ActiveSupport's pluralization mechanisms.

```rb
PageEz.configure do |config|
  config.on_pluralization_mismatch = :warn # or :raise, nil is the default
end
```

### Collisions with Capybara's RSpec Matchers

Capybara ships with a set of RSpec matchers, including:

* `have_title`
* `have_link`
* `have_button`
* `have_field`
* `have_select`
* `have_table`
* `have_text`

By default, if any elements are declared in PageEz that would overlap
with these matchers (e.g. `has_one :title, "h3"`), PageEz will raise an
exception in order to prevent confusing errors when asserting via predicate
matchers (since PageEz will define corresponding `has_title?` and
`has_no_title?` methods).

You can configure the behavior to warn (or do nothing):

```rb
PageEz.configure do |config|
  config.on_matcher_collision = :warn # or nil, :raise is the default
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
handles mounting HTML responses to endpoints accessible via `GET`. In tests,
call `build_page` with the markup you'd like and it will mount that response to
the root of the application.

```ruby
page = build_page(<<-HTML)
  <form>
    <input name="name" type="text" />
    <input name="email" type="text" />
  </form>
HTML
```

To drive interactions with a headless browser, add the RSpec metadata `:js` to
either individual `it`s or `describe`s.

## Roadmap

* [x] Verify page object interactions work within `within`
* [ ] Define `form` syntax
* [ ] Define `define` syntax (FactoryBot style)
* [x] Nested/reference-able page objects (from `define` syntax, by symbol, or by class name)

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
