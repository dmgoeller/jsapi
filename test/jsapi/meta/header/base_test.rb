# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Header
      class BaseTest < Minitest::Test
        include OpenAPITestHelper

        def test_raises_an_error_when_type_is_object
          error = assert_raises(ArgumentError) do
            Base.new(type: 'object')
          end
          assert_equal("type can't be object", error.message)
        end

        # OpenAPI objects

        def test_minimal_openapi_header_object
          header = Base.new(type: 'string')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                { type: 'string' }
              else
                {
                  schema:
                    if version == OpenAPI::V3_0
                      { type: 'string', nullable: true }
                    else
                      { type: %w[string null] }
                    end
                }
              end,
              header,
              version
            )
          end
        end

        def test_full_openapi_header_object
          header = Base.new(
            type: 'array',
            items: {
              type: 'string'
            },
            collection_format: 'pipes',
            description: 'foo',
            deprecated: true,
            example: 'bar',
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_equal(
              if version < OpenAPI::V3_0
                {
                  type: 'array',
                  items: {
                    type: 'string'
                  },
                  collection_format: 'pipes',
                  description: 'foo',
                  'x-foo': 'bar'
                }
              else
                {
                  schema:
                    if version < OpenAPI::V3_1
                      {
                        type: 'array',
                        nullable: true,
                        items: {
                          type: 'string',
                          nullable: true
                        }
                      }
                    else
                      {
                        type: %w[array null],
                        items: {
                          type: %w[string null]
                        }
                      }
                    end,
                  description: 'foo',
                  deprecated: true,
                  examples: {
                    'default' => {
                      value: 'bar'
                    }
                  },
                  'x-foo': 'bar'
                }
              end,
              header.to_openapi(version)
            )
          end
        end
      end
    end
  end
end
