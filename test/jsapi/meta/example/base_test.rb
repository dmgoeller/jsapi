# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Example
      class BaseTest < Minitest::Test
        include TestHelper

        def test_minimal_openapi_example_object
          example = Base.new(value: 'foo')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_2
                { value: 'foo' }
              else
                { dataValue: 'foo' }
              end,
              example,
              version
            )
          end
        end

        def test_full_openapi_example_object
          example = Base.new(
            summary: 'Foo',
            description: 'Lorem ipsum',
            value: 'foo',
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              {
                summary: 'Foo',
                description: 'Lorem ipsum',
                **if version < OpenAPI::V3_2
                    { value: 'foo' }
                  else
                    { dataValue: 'foo' }
                  end,
                'x-foo': 'bar'
              },
              example,
              version
            )
          end
        end

        def test_openapi_example_object_on_external
          example = Base.new(external_value: '/foo/bar')

          each_openapi_version do |version|
            assert_openapi_equal(
              { externalValue: '/foo/bar' },
              example,
              version
            )
          end
        end
      end
    end
  end
end
