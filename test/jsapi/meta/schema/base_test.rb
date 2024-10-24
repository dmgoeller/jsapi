# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class BaseTest < Minitest::Test
        def test_examples
          schema = Schema.new(type: 'string', example: 'foo')
          schema.add_example('bar')
          assert_equal(%w[foo bar], schema.examples)
        end

        def test_default_value
          schema = Schema.new(type: 'string', default: 'foo')
          assert_equal('foo', schema.default_value)
        end

        def test_default_value_on_general_default
          definitions = Definitions.new(
            defaults: {
              'string' => { within_requests: 'foo' }
            }
          )
          schema = Schema.new(type: 'string')
          assert_equal('foo', schema.default_value(definitions, context: :request))
        end

        def test_enum
          schema = Base.new(enum: %w[foo bar])
          assert_equal(%w[foo bar], schema.enum)

          validation = schema.validations['enum']
          assert_predicate(validation, :present?)
          assert_equal(%w[foo bar], validation.value)
        end

        def test_nullable_predicate
          schema = Base.new
          assert schema.nullable?
        end

        # JSON Schema objects

        def test_minimal_json_schema_object
          schema = Schema.new(
            type: 'string',
            existence: true
          )
          assert_equal(
            { type: 'string' },
            schema.to_json_schema
          )
        end

        def test_full_json_schema_object
          schema = Schema.new(
            type: 'string',
            existence: true,
            title: 'Title of foo',
            description: 'Lorem ipsum',
            default: 'foo',
            example: 'bar',
            deprecated: true
          )
          assert_equal(
            {
              type: 'string',
              title: 'Title of foo',
              description: 'Lorem ipsum',
              default: 'foo',
              examples: %w[bar],
              deprecated: true
            },
            schema.to_json_schema
          )
        end

        def test_json_schema_object_on_nullable
          schema = Schema.new(type: 'string', existence: :allow_null)
          assert_equal(
            {
              type: %w[string null]
            },
            schema.to_json_schema
          )
        end

        def test_json_schema_object_on_enum
          schema = Schema.new(type: 'string', enum: %w[foo bar])
          assert_equal(
            {
              type: %w[string null],
              enum: %w[foo bar]
            },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_minimal_openapi_schema_object
          schema = Schema.new(type: 'string', existence: true)

          %w[2.0 3.0 3.1].each do |version|
            assert_equal(
              { type: 'string' },
              schema.to_openapi(version)
            )
          end
        end

        def test_minimal_openapi_schema_object_on_nullable
          schema = Schema.new(type: 'string', existence: :allow_null)

          # OpenAPI 2.0
          assert_equal(
            { type: 'string' },
            schema.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            {
              type: 'string',
              nullable: true
            },
            schema.to_openapi('3.0')
          )
          # OpenAPI 3.1
          assert_equal(
            {
              type: %w[string null]
            },
            schema.to_openapi('3.1')
          )
        end

        def test_minimal_openapi_schema_object_on_enum
          schema = Schema.new(type: 'string', enum: %w[foo bar])

          # OpenAPI 2.0
          assert_equal(
            {
              type: 'string',
              enum: %w[foo bar]
            },
            schema.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            {
              type: 'string',
              nullable: true,
              enum: %w[foo bar]
            },
            schema.to_openapi('3.0')
          )
          # OpenAPI 3.1
          assert_equal(
            {
              type: %w[string null],
              enum: %w[foo bar]
            },
            schema.to_openapi('3.1')
          )
        end

        def test_full_openapi_schema_object
          schema = Schema.new(
            type: 'string',
            existence: true,
            title: 'Title of foo',
            description: 'Lorem ipsum',
            default: 'foo',
            example: 'bar',
            deprecated: true,
            external_docs: {
              url: 'https://foo.bar/docs'
            },
            openapi_extensions: { 'foo' => 'bar' }
          )
          # OpenAPI 2.0
          assert_equal(
            {
              type: 'string',
              title: 'Title of foo',
              description: 'Lorem ipsum',
              default: 'foo',
              example: 'bar',
              externalDocs: {
                url: 'https://foo.bar/docs'
              },
              'x-foo': 'bar'
            },
            schema.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            {
              type: 'string',
              title: 'Title of foo',
              description: 'Lorem ipsum',
              default: 'foo',
              examples: %w[bar],
              deprecated: true,
              externalDocs: {
                url: 'https://foo.bar/docs'
              },
              'x-foo': 'bar'
            },
            schema.to_openapi('3.0')
          )
          # OpenAPI 3.1
          assert_equal(
            {
              type: 'string',
              title: 'Title of foo',
              description: 'Lorem ipsum',
              default: 'foo',
              examples: %w[bar],
              deprecated: true,
              externalDocs: {
                url: 'https://foo.bar/docs'
              },
              'x-foo': 'bar'
            },
            schema.to_openapi('3.1')
          )
        end
      end
    end
  end
end
