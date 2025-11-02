# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class TagTest < Minitest::Test
      include OpenAPITestHelper

      def test_empty_openapi_tag_object
        tag = Tag.new

        each_openapi_version do |version|
          assert_openapi_equal({}, tag, version)
        end
      end

      def test_full_openapi_tag_object
        tag = Tag.new(
          name: 'Foo',
          summary: 'Summary of foo',
          description: 'Lorem ipsum',
          external_docs: {
            url: 'https://foo.bar/docs'
          },
          parent: 'Bar',
          kind: 'Category',
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            if version < OpenAPI::V3_2
              {
                name: 'Foo',
                description: 'Lorem ipsum',
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                'x-foo': 'bar'
              }
            else
              {
                name: 'Foo',
                summary: 'Summary of foo',
                description: 'Lorem ipsum',
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                parent: 'Bar',
                kind: 'Category',
                'x-foo': 'bar'
              }
            end,
            tag,
            version
          )
        end
      end
    end
  end
end
