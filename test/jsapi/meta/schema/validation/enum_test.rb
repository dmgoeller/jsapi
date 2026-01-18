# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class EnumTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_enum
            error = assert_raises(ArgumentError) { Enum.new(nil) }
            assert_equal('invalid enum: nil', error.message)
          end

          def test_validates_enum
            enum = Enum.new(%w[A B C])

            errors = Jsapi::Model::Errors.new
            assert(enum.validate('A', errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert_not(enum.validate('D', errors))
            assert(errors.added?(:base, 'is not included in the list'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { enum: %w[foo bar] },
              Enum.new(%w[foo bar]).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { enum: %w[foo bar] },
              Enum.new(%w[foo bar]).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
