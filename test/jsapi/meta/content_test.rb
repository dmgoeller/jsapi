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
            Media::Type.new('application', 'json-seq')
          )
        end
      end
    end
  end
end
