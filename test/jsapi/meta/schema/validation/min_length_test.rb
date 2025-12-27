# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MinLengthTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_min_length
            error = assert_raises(ArgumentError) { MinLength.new(nil) }
            assert_equal('invalid min length: nil', error.message)
          end

          def test_validates_min_length
            min_length = MinLength.new(3)

            errors = Jsapi::Model::Errors.new
            assert(min_length.validate('foo', errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!min_length.validate('fo', errors))
            assert(errors.added?(:base, 'is too short (minimum is 3 characters)'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { minLength: 2 },
              MinLength.new(2).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { minLength: 2 },
              MinLength.new(2).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
