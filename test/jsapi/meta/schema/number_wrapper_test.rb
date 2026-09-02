# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class NumberWrapperTest < Minitest::Test
        include WrapperTestHelper

        def test_jsonify
          wrapper = wrap_schema

          assert_json_equal(1.0, wrapper, 1)
          assert_json_equal(1.0, wrapper, 1.0)
          assert_json_equal(1.0, wrapper, '1')
          assert_json_equal(nil, wrapper, nil)
        end

        def test_jsonify_on_schema_with_conversion
          wrapper = wrap_schema(conversion: :abs)

          assert_json_equal(1.0, wrapper, -1.0)
        end
      end
    end
  end
end
