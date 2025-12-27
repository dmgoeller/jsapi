# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MaximumTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_maximum
            error = assert_raises(ArgumentError) { Maximum.new(nil) }
            assert_equal('invalid maximum: nil', error.message)
          end

          def test_raises_exception_on_invalid_exclusive_maximum
            error = assert_raises(ArgumentError) { Maximum.new(nil, exclusive: true) }
            assert_equal('invalid exclusive maximum: nil', error.message)
          end

          def test_validates_maximum
            maximum = Maximum.new(0)

            errors = Jsapi::Model::Errors.new
            assert(maximum.validate(0, errors))
            assert_predicate(errors, :none?)

            errors = Jsapi::Model::Errors.new
            assert(!maximum.validate(1, errors))
            assert(errors.added?(:base, 'must be less than or equal to 0'))
          end

          def test_validates_exclusive_maximum
            exclusive_maximum = Maximum.new(0, exclusive: true)

            errors = Jsapi::Model::Errors.new
            assert(exclusive_maximum.validate(-1, errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!exclusive_maximum.validate(0, errors))
            assert(errors.added?(:base, 'must be less than 0'))
          end

          # JSON Schema objects

          def test_to_json_schema_on_maximum
            assert_json_equal(
              { maximum: 0 },
              Maximum.new(0).to_json_schema_validation
            )
          end

          def test_to_json_schema_on_exclusive_maximum
            assert_json_equal(
              { exclusiveMaximum: 0 },
              Maximum.new(0, exclusive: true).to_json_schema_validation
            )
          end

          # OpenAPI objects

          def test_to_openapi_validation_on_maximum
            maximum = Maximum.new(0)

            each_openapi_version(from: OpenAPI::V3_0) do |version|
              assert_json_equal(
                { maximum: 0 },
                maximum.to_openapi_validation(version)
              )
            end
          end

          def test_to_openapi_validation_on_exclusive_maximum
            maximum = Maximum.new(0, exclusive: true)

            each_openapi_version(from: OpenAPI::V3_0) do |version|
              assert_json_equal(
                if version == OpenAPI::V3_0
                  {
                    maximum: 0,
                    exclusiveMaximum: true
                  }
                else
                  { exclusiveMaximum: 0 }
                end,
                maximum.to_openapi_validation(version)
              )
            end
          end
        end
      end
    end
  end
end
