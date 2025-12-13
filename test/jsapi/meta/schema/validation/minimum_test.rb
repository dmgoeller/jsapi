# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class MinimumTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_minimum
            error = assert_raises(ArgumentError) { Minimum.new(nil) }
            assert_equal('invalid minimum: nil', error.message)
          end

          def test_raises_exception_on_invalid_exclusive_minimum
            error = assert_raises(ArgumentError) { Minimum.new(nil, exclusive: true) }
            assert_equal('invalid exclusive minimum: nil', error.message)
          end

          def test_validates_minimum
            minimum = Minimum.new(0)

            errors = Jsapi::Model::Errors.new
            assert(minimum.validate(0, errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!minimum.validate(-1, errors))
            assert(errors.added?(:base, 'must be greater than or equal to 0'))
          end

          def test_validates_exclusive_minimum
            minimum = Minimum.new(0, exclusive: true)

            errors = Jsapi::Model::Errors.new
            assert(minimum.validate(1, errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!minimum.validate(0, errors))
            assert(errors.added?(:base, 'must be greater than 0'))
          end

          # JSON Schema objects

          def test_to_json_schema_on_minimum
            assert_json_equal(
              { minimum: 0 },
              Minimum.new(0).to_json_schema_validation
            )
          end

          def test_to_json_schema_on_exclusive_minimum
            assert_json_equal(
              { exclusiveMinimum: 0 },
              Minimum.new(0, exclusive: true).to_json_schema_validation
            )
          end

          # OpenAPI objects

          def test_to_openapi_validation_on_minimum
            minimum = Minimum.new(0)

            each_openapi_version(from: OpenAPI::V3_0) do |version|
              assert_json_equal(
                { minimum: 0 },
                minimum.to_openapi_validation(version)
              )
            end
          end

          def test_to_openapi_validation_on_exclusive_minimum
            minimum = Minimum.new(0, exclusive: true)

            each_openapi_version(from: OpenAPI::V3_0) do |version|
              assert_json_equal(
                if version == OpenAPI::V3_0
                  {
                    minimum: 0,
                    exclusiveMinimum: true
                  }
                else
                  { exclusiveMinimum: 0 }
                end,
                minimum.to_openapi_validation(version)
              )
            end
          end
        end
      end
    end
  end
end
