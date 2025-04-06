# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Response
      class BaseTest < Minitest::Test
        def test_type
          response = Base.new(type: 'string')
          assert_equal('string', response.type)
        end

        def test_example
          response = Base.new(type: 'string', example: 'foo')
          assert_equal('foo', response.example.value)
        end

        def test_schema
          response = Base.new(schema: 'bar')
          assert_equal('bar', response.schema.ref)
        end

        def test_json_type_predicate
          %w[application/json application/vnd.foo+json text/json].each do |content_type|
            assert(
              Base.new(content_type: content_type).json_type?,
              "Expected #{content_type} to be a JSON type"
            )
          end

          %w[application/pdf text/plain].each do |content_type|
            assert(
              !Base.new(content_type: content_type).json_type?,
              "Expected #{content_type} not to be a JSON type"
            )
          end
        end

        # OpenAPI objects

        def test_minimal_openapi_response_object
          response = Base.new(type: 'string', existence: true)

          # OpenAPI 2.0
          assert_equal(
            {
              schema: {
                type: 'string'
              }
            },
            response.to_openapi('2.0', Definitions.new)
          )
          # OpenAPI 3.0
          assert_equal(
            {
              content: {
                'application/json' => {
                  schema: {
                    type: 'string'
                  }
                }
              }
            },
            response.to_openapi('3.0', Definitions.new)
          )
        end

        def test_full_openapi_response_object
          response = Base.new(
            content_type: 'application/foo',
            type: 'string',
            existence: false,
            example: 'foo',
            headers: {
              'X-Foo' => { type: 'string' },
              'X-Bar' => { ref: 'X-Bar' }
            },
            links: {
              'foo' => { operation_id: 'foo' }
            },
            openapi_extensions: { 'foo' => 'bar' }
          )
          # OpenAPI 2.0
          assert_equal(
            {
              schema: {
                type: 'string'
              },
              headers: {
                'X-Foo' => {
                  type: 'string'
                }
              },
              examples: {
                'application/foo' => 'foo'
              },
              'x-foo': 'bar'
            },
            response.to_openapi('2.0', Definitions.new)
          )
          # OpenAPI 3.0
          assert_equal(
            {
              content: {
                'application/foo' => {
                  schema: {
                    type: 'string',
                    nullable: true
                  },
                  examples: {
                    'default' => {
                      value: 'foo'
                    }
                  }
                }
              },
              headers: {
                'X-Foo' => {
                  schema: {
                    type: 'string',
                    nullable: true
                  }
                },
                'X-Bar' => {
                  '$ref': '#/components/headers/X-Bar'
                }
              },
              links: {
                'foo' => {
                  operationId: 'foo'
                }
              },
              'x-foo': 'bar'
            },
            response.to_openapi('3.0', Definitions.new)
          )
        end
      end
    end
  end
end
