# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class ArrayTest < Minitest::Test
        include JSONTestHelper
        include OpenAPITestHelper

        def test_items
          assert_equal('string', Array.new(items: { type: 'string' }).items.type)
          assert_equal('foo', Array.new(items: { ref: 'foo' }).items.ref)
          assert_equal('foo', Array.new(items: { schema: 'foo' }).items.ref)
        end

        def test_max_items
          schema = Array.new(items: { type: 'string' }, max_items: 3)
          assert_equal(3, schema.max_items)

          validation = schema.validations['max_items']
          assert_predicate(validation, :present?)
          assert_equal(3, validation.value)
        end

        def test_min_items
          schema = Array.new(items: { type: 'string' }, min_items: 3)
          assert_equal(3, schema.min_items)

          validation = schema.validations['min_items']
          assert_predicate(validation, :present?)
          assert_equal(3, validation.value)
        end

        # JSON Schema objects

        def test_minimal_json_schema_object
          schema = Array.new(existence: true)
          assert_json_equal(
            {
              type: 'array',
              items: {}
            },
            schema.to_json_schema
          )
        end

        def test_json_schema_object
          schema = Array.new(items: { type: 'string' }, existence: false)
          assert_json_equal(
            {
              type: %w[array null],
              items: {
                type: %w[string null]
              }
            },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_minimal_openapi_schema_object
          schema = Array.new(existence: true)

          each_openapi_version do |version|
            assert_openapi_equal(
              {
                type: 'array',
                items: {}
              },
              schema,
              version
            )
          end
        end

        def test_openapi_schema_object
          schema = Array.new(items: { type: 'string' }, existence: false)

          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  type: 'array',
                  items: {
                    type: 'string'
                  }
                }
              when OpenAPI::V3_0
                {
                  type: 'array',
                  nullable: true,
                  items: {
                    type: 'string',
                    nullable: true
                  }
                }
              else
                {
                  type: %w[array null],
                  items: {
                    type: %w[string null]
                  }
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
