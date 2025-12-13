# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class StringTest < Minitest::Test
        include TestHelper

        def test_max_length
          schema = String.new(max_length: 10)
          assert_equal(10, schema.max_length)

          validation = schema.validations['max_length']
          assert_predicate(validation, :present?)
          assert_equal(10, validation.value)
        end

        def test_max_length_raises_an_error_when_attributes_are_frozen
          schema = String.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.max_length = 10
          end
        end

        def test_min_length
          schema = String.new(min_length: 10)
          assert_equal(10, schema.min_length)

          validation = schema.validations['min_length']
          assert_predicate(validation, :present?)
          assert_equal(10, validation.value)
        end

        def test_min_length_raises_an_error_when_attributes_are_frozen
          schema = String.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.min_length = 10
          end
        end

        def test_pattern
          schema = String.new(pattern: /foo/)
          assert_equal(/foo/, schema.pattern)

          validation = schema.validations['pattern']
          assert_predicate(validation, :present?)
          assert_equal('foo', validation.value.source)
        end

        def test_pattern_raises_an_error_when_attributes_are_frozen
          schema = String.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.pattern = /foo/
          end
        end

        # JSON Schema objects

        def test_minimal_json_schema_object
          schema = String.new
          assert_json_equal(
            {
              type: %w[string null]
            },
            schema.to_json_schema
          )
        end

        def test_json_schema_object
          schema = String.new(format: 'date')
          assert_json_equal(
            {
              type: %w[string null],
              format: 'date'
            },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_minimal_openapi_schema_object
          schema = String.new

          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_1
                {
                  type: 'string',
                  nullable: true
                }
              else
                {
                  type: %w[string null]
                }
              end,
              schema,
              version
            )
          end
        end

        def test_openapi_schema_object
          schema = String.new(format: 'date')

          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_1
                {
                  type: 'string',
                  nullable: true,
                  format: 'date'
                }
              else
                {
                  type: %w[string null],
                  format: 'date'
                }
              end,
              schema,
              version
            )
          end
        end
      end
    end
  end
end
