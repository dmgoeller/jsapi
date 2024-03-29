# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ExampleTest < Minitest::Test
      def test_openapi_example
        example = Example.new(
          summary: 'Foo',
          description: 'Description of foo',
          value: 'foo'
        )
        assert_equal(
          {
            summary: 'Foo',
            description: 'Description of foo',
            value: 'foo'
          },
          example.to_openapi_example
        )
      end

      def test_openapi_external_example
        example = Example.new(
          summary: 'Foo',
          description: 'Description of foo',
          value: '/foo/bar',
          external: true
        )
        assert_equal(
          {
            summary: 'Foo',
            description: 'Description of foo',
            external_value: '/foo/bar'
          },
          example.to_openapi_example
        )
      end
    end
  end
end
