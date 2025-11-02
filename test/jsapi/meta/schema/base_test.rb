# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class BaseTest < Minitest::Test
        include OpenAPITestHelper

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

          each_openapi_version do |version|
            assert_equal(
              { type: 'string' },
              schema.to_openapi(version)
            )
          end
        end

        def test_minimal_openapi_schema_object_on_nullable
          schema = Schema.new(type: 'string', existence: :allow_null)

          each_openapi_version do |version|
            assert_equal(
              case version
              when OpenAPI::V2_0
                { type: 'string' }
              when OpenAPI::V3_0
                {
                  type: 'string',
                  nullable: true
                }
              else
                {
                  type: %w[string null]
                }
              end,
              schema.to_openapi(version)
            )
          end
        end

        def test_minimal_openapi_schema_object_on_enum
          schema = Schema.new(type: 'string', enum: %w[foo bar])

          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  type: 'string',
                  enum: %w[foo bar]
                }
              when OpenAPI::V3_0
                {
                  type: 'string',
                  nullable: true,
                  enum: %w[foo bar]
                }
              else
                {
                  type: %w[string null],
                  enum: %w[foo bar]
                }
              end,
              schema,
              version
            )
          end
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
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
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
                }
              when OpenAPI::V3_0
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
                }
              else
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
