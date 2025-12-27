# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MultipleOfTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_multiple_of
            error = assert_raises(ArgumentError) { MultipleOf.new(nil) }
            assert_equal('invalid multiple of: nil', error.message)
          end

          def test_validates_multiple_of
            multiple_of = MultipleOf.new(2)

            errors = Jsapi::Model::Errors.new
            assert(multiple_of.validate(4, errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!multiple_of.validate(3, errors))
            assert(errors.added?(:base, 'is invalid'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { multipleOf: 2 },
              MultipleOf.new(2).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { multipleOf: 2 },
              MultipleOf.new(2).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
