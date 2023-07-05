require "spec_helper"

RSpec.describe PageEz::Configuration do
  it "disallows invalid values for on_pluralization_mismatch" do
    expect do
      PageEz.configure do |config|
        config.on_pluralization_mismatch = :invalid
      end
    end.to raise_error(ArgumentError, ":invalid must be one of [:warn, :raise, nil]")
  end
end
