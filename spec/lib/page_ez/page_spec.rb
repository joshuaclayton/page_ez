require "spec_helper"
require "logger"

RSpec.describe PageEz::Page do
  it "logs declarations" do
    logger = configure_fake_logger

    Class.new(PageEz::Page) do
      has_one :list, "ul" do
        has_many :items, "li" do
          has_one :name, "span"
        end
      end
    end

    expect(logger.debugs).to contain_in_order(
      "has_one :list, \"ul\"",
      "  has_many :items, \"li\"",
      "    has_one :name, \"span\""
    )

    logger.reset

    Class.new(PageEz::Page) do
      has_one :dashboard, "section" do
        has_many :cards, "li[data-role=card]" do
          has_one :title, "h3"
        end

        has_many_ordered :contacts, "li[data-role=contact]" do
          has_one :name, "h3"
        end
      end
    end

    expect(logger.debugs).to contain_in_order(
      "has_one :dashboard, \"section\"",
      "  has_many :cards, \"li[data-role=card]\"",
      "    has_one :title, \"h3\"",
      "  has_many_ordered :contacts, \"li[data-role=contact]\"",
      "    has_one :name, \"h3\""
    )
  end

  it "logs page object names" do
    logger = configure_fake_logger

    # rubocop:disable Lint/ConstantDefinitionInBlock
    class Homepage < PageEz::Page
    end

    class TodosIndex < PageEz::Page
    end

    module Nested
      class Dashboard < PageEz::Page
      end

      class LoggedInDashboard < Dashboard
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    Class.new(PageEz::Page)

    expect(logger.debugs).to contain_in_order(
      "Declaring page object: Homepage",
      "Declaring page object: TodosIndex",
      "Declaring page object: Nested::Dashboard",
      "Declaring page object: Nested::LoggedInDashboard",
      "Declaring page object: {anonymous page object}"
    )
  end
end
