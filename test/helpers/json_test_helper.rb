# frozen_string_literal: true

module JSONTestHelper
  def assert_json_equal(expected, actual)
    expected, actual = expected&.as_json, actual&.as_json

    assert(
      expected == actual,
      if expected.nil?
        <<~MESSAGE
          Expected JSON to be nil.

          Actual:
          #{JSON.pretty_generate(actual)}
        MESSAGE
      else
        <<~MESSAGE
          Expected JSON to be:
          #{JSON.pretty_generate(expected)}

          Actual:
          #{JSON.pretty_generate(actual)}
        MESSAGE
      end
    )
  end
end
