# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class TagTest < Minitest::Test
      def test_empty_openapi_tag_object
        assert_equal({}, Tag.new.to_openapi)
      end

      def test_full_openapi_tag_object
        tag = Tag.new(
          name: 'Foo',
          description: 'Lorem ipsum',
          external_docs: {
            url: 'https://foo.bar/docs'
          },
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_equal(
          {
            name: 'Foo',
            description: 'Lorem ipsum',
            externalDocs: {
              url: 'https://foo.bar/docs'
            },
            'x-foo': 'bar'
          },
          tag.to_openapi
        )
      end
    end
  end
end
