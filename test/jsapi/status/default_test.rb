# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Status
    class DefaultTest < Minitest::Test
      def test_match
        [nil, Code.from(200)].each do |status_code|
          assert(
            DEFAULT.match?(status_code),
            "Expected #{status_code.inspect} to match #{DEFAULT.inspect}."
          )
        end
      end
    end
  end
end
