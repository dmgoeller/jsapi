# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class ExternalDocumentationTest < Minitest::Test
      include TestHelper

      def test_empty_openapi_external_documentation_object
        assert_equal({}, ExternalDocumentation.new.to_openapi)
      end

      def test_full_openapi_external_documentation_object
        external_documentation = ExternalDocumentation.new(
          url: 'https://foo.bar/docs',
          description: 'Foo',
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_openapi_equal(
          {
            url: 'https://foo.bar/docs',
            description: 'Foo',
            'x-foo': 'bar'
          },
          external_documentation,
          nil
        )
      end
    end
  end
end
