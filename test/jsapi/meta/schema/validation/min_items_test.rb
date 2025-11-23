# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MinItemsTest < Minitest::Test
          include JSONTestHelper

          def test_raises_exception_on_invalid_min_length
            error = assert_raises(ArgumentError) { MinItems.new(nil) }
            assert_equal('invalid min items: nil', error.message)
          end

          def test_validates_min_items
            min_items = MinItems.new(2)

            errors = Jsapi::Model::Errors.new
            assert(min_items.validate(%w[foo bar], errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!min_items.validate(%w[foo], errors))
            assert(errors.added?(:base, 'is invalid'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { minItems: 2 },
              MinItems.new(2).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { minItems: 2 },
              MinItems.new(2).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
