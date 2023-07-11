require "spec_helper"

RSpec.describe PageEz::Configuration do
  it "disallows invalid values for on_pluralization_mismatch" do
    expect do
      PageEz.configure do |config|
        config.on_pluralization_mismatch = :invalid
      end
    end.to raise_error(ArgumentError, ":invalid must be one of [:warn, :raise, nil]")
  end

  it "disallows selector extensions with non-keyword arguments beyond name" do
    expect do
      PageEz.configure do |config|
        config.register_selector(:by_data_role) do |name, id|
          "this-should-break"
        end
      end
    end.to raise_error(ArgumentError, ":by_data_role can only accept keyword arguments beyond name")
  end
end
