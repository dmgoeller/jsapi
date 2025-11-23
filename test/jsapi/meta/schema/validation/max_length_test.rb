# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MaxLengthTest < Minitest::Test
          include JSONTestHelper

          def test_raises_exception_on_invalid_max_length
            error = assert_raises(ArgumentError) { MaxLength.new(nil) }
            assert_equal('invalid max length: nil', error.message)
          end

          def test_validates_max_length
            max_length = MaxLength.new(3)

            errors = Jsapi::Model::Errors.new
            assert(max_length.validate('foo', errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!max_length.validate('foo bar', errors))
            assert(errors.added?(:base, 'is too long (maximum is 3 characters)'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { maxLength: 2 },
              MaxLength.new(2).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { maxLength: 2 },
              MaxLength.new(2).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
