RSpec::Matchers.define :contain_in_order do |*expected|
  match do |actual|
    actual_ = actual.dup

    result = expected.map do |expected_|
      actual_.index(expected_).tap do |index|
        actual_.delete_at(index) if index
      end
    end

    result == result.compact && result == result.sort
  end
end
