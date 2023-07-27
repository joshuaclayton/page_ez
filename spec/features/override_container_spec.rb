require "spec_helper"

RSpec.describe "overriding container" do
  it "works by scoping the first portion" do
    page = build_page(<<-HTML)
    <div data-role="slot-1">
      <section>
        <heading>
          <h2>Heading 1</h2>
        </heading>
        <div data-role="content">
          <p>Paragraph 1</p>
          <p>Paragraph 2</p>
          <p>Paragraph 3</p>
        </div>
      </section>
    </div>
    <div data-role="slot-2">
      <section>
        <heading>
          <h2>Heading 2</h2>
        </heading>
        <div data-role="content">
          <p>Paragraph 4</p>
          <p>Paragraph 5</p>
          <p>Paragraph 6</p>
        </div>
      </section>
    </div>
    HTML

    test_page = Class.new(PageEz::Page) do
      has_one :section do
        has_one :heading do
          has_one :body, "h2"
        end

        has_one :primary_content, "[data-role=content]" do
          has_many_ordered :paragraphs, "p"
        end
      end
    end

    slot_one_class = Class.new(test_page) do
      base_selector "[data-role=slot-1]"
    end

    slot_two_class = Class.new(test_page) do
      base_selector "[data-role=slot-2]"
    end

    sub_slot_one = Class.new(slot_one_class).new(page)

    page.visit "/"

    aggregate_failures "composition works with classes that have a base_selector already defined" do
      wrapper = Class.new(PageEz::Page) do
        has_one :slot_one, slot_one_class
        has_one :slot_two, slot_two_class
      end.new(page)

      expect(wrapper.slot_one).to match_slot_one_values
      expect(wrapper.slot_two).to match_slot_two_values
    end

    aggregate_failures "composition works with classes that have a base_selector already defined" do
      wrapper = Class.new(PageEz::Page) do
        has_one :slot_one_flipped, slot_one_class, base_selector: "[data-role=slot-2]"
        has_one :slot_two_flipped, slot_two_class, base_selector: "[data-role=slot-1]"
      end.new(page)

      expect(wrapper.slot_two_flipped).to match_slot_one_values
      expect(wrapper.slot_one_flipped).to match_slot_two_values
    end

    aggregate_failures "composition sets the base_selector when no base selector is set" do
      wrapper = Class.new(PageEz::Page) do
        has_one :slot_one, test_page, base_selector: "[data-role=slot-1]"
        has_one :slot_two, test_page, base_selector: "[data-role=slot-2]"
      end.new(page)

      expect(wrapper.slot_one).to match_slot_one_values
      expect(wrapper.slot_two).to match_slot_two_values
    end

    aggregate_failures "#within scopes to the correct container" do
      within "[data-role=slot-1]" do
        expect(test_page.new(page)).to match_slot_one_values
      end

      within "[data-role=slot-2]" do
        expect(test_page.new(page)).to match_slot_two_values
      end
    end

    aggregate_failures "no base_selector results in ambiguous matches" do
      expect do
        test_page.new(page).section
      end.to raise_error(Capybara::Ambiguous)

      expect do
        Class.new(slot_one_class) do
          base_selector nil
        end.new(page).section
      end.to raise_error(Capybara::Ambiguous)
    end

    expect(sub_slot_one).to match_slot_one_values
    expect(slot_one_class.new(page)).to match_slot_one_values
    expect(slot_two_class.new(page)).to match_slot_two_values
  end

  def match_slot_one_values
    MatchesSlotOne.new
  end

  def match_slot_two_values
    MatchesSlotTwo.new
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  class MatchesSlotOne
    def matches?(target)
      @target = target
      @target.section.heading.has_body?(text: "Heading 1") &&
        @target.section.primary_content.has_paragraph_at?(0, text: "Paragraph 1") &&
        @target.section.primary_content.has_paragraph_at?(1, text: "Paragraph 2") &&
        @target.section.primary_content.has_paragraph_at?(2, text: "Paragraph 3")
    end

    def failure_message
      "expected #{@target} to match slot one values"
    end
  end

  class MatchesSlotTwo
    def matches?(target)
      @target = target
      @target.section.heading.has_body?(text: "Heading 2") &&
        @target.section.primary_content.has_paragraph_at?(0, text: "Paragraph 4") &&
        @target.section.primary_content.has_paragraph_at?(1, text: "Paragraph 5") &&
        @target.section.primary_content.has_paragraph_at?(2, text: "Paragraph 6")
    end

    def failure_message
      "expected #{@target} to match slot two values"
    end
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock
end
