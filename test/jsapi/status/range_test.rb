# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Status
    class RangeTest < Minitest::Test
      def test_match
        range = Range::CLIENT_ERROR

        [Code.from(400), Code.from(499)].each do |status_code|
          assert(
            range.match?(status_code),
            "Expected #{status_code.inspect} to match #{range.inspect}."
          )
        end

        [nil, Code.from(399), Code.from(500)].each do |status_code|
          assert_not(
            range.match?(status_code),
            "Expected #{status_code.inspect} not to match #{range.inspect}."
          )
        end
      end
    end
  end
end
