# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class ContentTest < Minitest::Test
      include TestHelper

      def test_content_with_example
        content = Content.new(type: 'string', example: 'foo')
        assert_equal('foo', content.example.value)
      end

      def test_content_with_schema_reference
        content = Content.new(schema: 'bar')
        assert_equal('bar', content.schema.ref)
      end

      # Example values

      def test_example_value
        content = Content.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          },
          examples: {
            'default' => {
              value: lambda do |builder|
                builder.generate_json({ foo: 'bar' })
              end
            }
          }
        )
        assert_equal(
          { 'foo' => 'bar' },
          content.example_data_value(Definitions.new).as_json
        )
      end

      def test_localized_example_value
        definitions = Definitions.new

        content = Content.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          },
          examples: {
            'default' => {
              value: lambda do |builder|
                builder.generate_json(
                  Class.new do
                    def foo
                      I18n.t(:hello_world)
                    end
                  end.new
                )
              end
            }
          }
        )
        assert_equal(
          { 'foo' => 'Hello world' },
          content.example_data_value(definitions, locale: :en).as_json
        )
        assert_equal(
          { 'foo' => 'Hallo Welt' },
          content.example_data_value(definitions, locale: :de).as_json
        )
      end

      def test_example_value_on_reference
        definitions = Definitions.new(
          examples: {
            'response' => {
              value: lambda do |builder|
                builder.generate_json({ foo: 'bar' })
              end
            }
          }
        )
        content = Content.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          },
          examples: {
            'default' => { ref: 'response' }
          }
        )
        assert_equal(
          { 'foo' => 'bar' },
          content.example_data_value(definitions).as_json
        )
      end

      # OpenAPI objects

      def test_minimal_openapi_media_type_object
        content = Content.new(
          type: 'string',
          existence: true
        )
        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal(
            {
              schema: {
                type: 'string'
              }
            },
            content,
            version
          )
        end
      end

      def test_full_openapi_media_type_object
        content = Content.new(
          type: 'string',
          existence: true,
          example: 'foo',
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal(
            {
              schema: {
                type: 'string'
              },
              examples: {
                'default' =>
                  if version < OpenAPI::V3_2
                    { value: 'foo' }
                  else
                    { dataValue: 'foo' }
                  end
              },
              'x-foo': 'bar'
            },
            content,
            version
          )
        end
      end

      def test_openapi_media_type_object_on_json_seq
        content = Content.new(
          type: 'array',
          items: {
            type: 'string',
            existence: true
          },
          existence: true
        )
        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal(
            if version < OpenAPI::V3_2
              {
                schema: {
                  type: 'array',
                  items: { type: 'string' }
                }
              }
            else
              {
                itemSchema: {
                  type: 'string'
                }
              }
            end,
            content,
            version,
            media_type: Media::Type.new('application', 'json-seq')
          )
        end
      end

      def test_openapi_media_type_object_with_lazily_created_example
        definitions = Definitions.new

        content = Content.new(
          type: 'object',
          existence: true,
          properties: {
            'foo' => {
              type: 'string',
              existence: true
            }
          },
          examples: {
            'default' => {
              value: lambda do |builder|
                builder.generate_json({ foo: 'bar' })
              end
            }
          }
        )
        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal(
            {
              schema: {
                type: 'object',
                properties: {
                  'foo' => { type: 'string' }
                },
                required: %w[foo]
              },
              examples: {
                'default':
                  if version < OpenAPI::V3_2
                    { value: { foo: 'bar' } }
                  else
                    { dataValue: { foo: 'bar' } }
                  end
              }
            },
            content,
            version,
            definitions
          )
        end
      end
    end
  end
end
