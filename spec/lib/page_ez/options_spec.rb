require "spec_helper"

RSpec.describe PageEz::Options do
  it "returns vanilla options" do
    expect(described_class.merge(foo: 1)).to eq(foo: 1)
  end

  it "returns vanilla options with dynamic options" do
    expect(described_class.merge({foo: 2}, ->(foo:) { {bar: foo} }, foo: 1)).to eq(foo: 2, bar: 1)
  end

  it "extracts the correct options" do
    expect(described_class.merge({}, ->(foo:) { {bar: foo} }, foo: 1, baz: 2)).to eq(bar: 1, baz: 2)
  end

  it "handles args with kwargs" do
    expect(described_class.merge({}, ->(first, foo:) { {first: first, bar: foo} }, "first", {foo: 1, baz: 2})).to eq(first: "first", bar: 1, baz: 2)
  end
end
