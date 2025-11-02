# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Example
      class BaseTest < Minitest::Test
        include OpenAPITestHelper

        def test_minimal_openapi_example_object
          example = Base.new(value: 'foo')

          assert_openapi_equal(
            { value: 'foo' },
            example,
            nil
          )
        end

        def test_full_openapi_example_object
          example = Base.new(
            summary: 'Foo',
            description: 'Lorem ipsum',
            value: 'foo',
            openapi_extensions: { 'foo' => 'bar' }
          )
          assert_equal(
            {
              summary: 'Foo',
              description: 'Lorem ipsum',
              value: 'foo',
              'x-foo': 'bar'
            },
            example.to_openapi
          )
        end

        def test_openapi_example_object_on_external
          example = Base.new(
            value: '/foo/bar',
            external: true
          )
          assert_openapi_equal(
            { externalValue: '/foo/bar' },
            example,
            nil
          )
        end
      end
    end
  end
end
