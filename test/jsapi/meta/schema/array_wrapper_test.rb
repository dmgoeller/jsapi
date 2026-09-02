# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class ArrayWrapperTest < Minitest::Test
        include WrapperTestHelper

        def test_items
          items = Array::Wrapper.new(
            array = Array.new(
              items: {}
            ),
            Definitions.new
          ).items

          assert_kind_of(Schema::Wrapper, items)
          assert_equal(array.items, items.__getobj__)
        end

        def test_jsonify
          wrapper = wrap_schema(items: { type: 'string' })

          [%w[foo bar], [nil], [], nil].each do |value|
            assert_json_equal(value, wrapper, value)
          end
        end

        def test_jsonify_on_schema_disallowing_nil_items
          wrapper = wrap_schema(
            items: {
              type: 'string',
              existence: :allow_empty
            }
          )
          [%w[foo bar], [], nil].each do |value|
            assert_json_equal(value, wrapper, value)
          end

          error = assert_raises(JsonifyError) { wrapper.jsonify([nil]) }
          assert_equal "[0] can't be nil", error.message
        end
      end
    end
  end
end
