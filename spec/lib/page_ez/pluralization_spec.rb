require "spec_helper"

RSpec.describe PageEz::Pluralization do
  it "behaves correctly" do
    aggregate_failures("words are singular/plural correctly") do
      singular_and_plural_words.each do |singular, plural|
        expect(described_class.new(singular)).to be_singular
        expect(described_class.new(plural)).to be_plural
      end
    end

    aggregate_failures("when pluralizing") do
      singular_and_plural_words.each do |singular, plural|
        expect(described_class.new(singular).pluralize).to eq(plural)
        expect(described_class.new(plural).pluralize).to eq(plural)
      end
    end

    aggregate_failures("when singularizing") do
      singular_and_plural_words.each do |singular, plural|
        expect(described_class.new(plural).singularize).to eq(singular)
        expect(described_class.new(singular).singularize).to eq(singular)
      end
    end
  end

  def singular_and_plural_words
    {
      "list" => "lists",
      "awesome_list" => "awesome_lists",
      "section" => "sections",
      "ox" => "oxen",
      "item" => "items",
      "form" => "forms"
    }
  end
end
