# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class BooleanWrapperTest < Minitest::Test
        include WrapperTestHelper

        def test_jsonify
          wrapper = wrap_schema

          # Truthy values
          assert_json_equal(true, wrapper, true)
          assert_json_equal(true, wrapper, '')

          # Falsely values
          assert_json_equal(false, wrapper, false)
          assert_json_equal(nil, wrapper, nil)
        end
      end
    end
  end
end
