# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Response
      class BaseTest < Minitest::Test
        include OpenAPITestHelper

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
              "Expected #{content_type.inspect} to be a JSON type"
            )
          end

          %w[application/json-seq text/plain].each do |content_type|
            assert(
              !Base.new(content_type: content_type).json_type?,
              "Expected #{content_type.inspect} not to be a JSON type"
            )
          end
        end

        def test_json_seq_type_predicate
          assert(
            Base.new(content_type: 'application/json-seq').json_seq_type?,
            'Expected "application/json-seq" to be a JSON sequence text format type'
          )
          assert(
            !Base.new(content_type: 'application/json').json_seq_type?,
            'Expected "application/json" not to be a JSON sequence text format type'
          )
        end

        # OpenAPI objects

        def test_minimal_openapi_response_object
          response = Base.new(type: 'string', existence: true)

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                {
                  schema: {
                    type: 'string'
                  }
                }
              else
                {
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'string'
                      }
                    }
                  }
                }
              end,
              response,
              version,
              nil
            )
          end
        end

        def test_full_openapi_response_object
          response = Base.new(
            summary: 'Summary of foo',
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
          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
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
                }
              else
                {
                  **if version >= OpenAPI::V3_2
                      { summary: 'Summary of foo' }
                    else
                      {}
                    end,
                  headers: {
                    'X-Foo' => {
                      schema:
                        if version < OpenAPI::V3_1
                          {
                            type: 'string',
                            nullable: true
                          }
                        else
                          { type: %w[string null] }
                        end
                    },
                    'X-Bar' => {
                      '$ref': '#/components/headers/X-Bar'
                    }
                  },
                  content: {
                    'application/foo' => {
                      schema:
                        if version < OpenAPI::V3_1
                          {
                            type: 'string',
                            nullable: true
                          }
                        else
                          { type: %w[string null] }
                        end,
                      examples: {
                        'default' => {
                          value: 'foo'
                        }
                      }
                    }
                  },
                  links: {
                    'foo' => {
                      operationId: 'foo'
                    }
                  },
                  'x-foo': 'bar'
                }
              end,
              response,
              version,
              nil
            )
          end
        end

        def test_openapi_response_object_on_json_seq
          response = Base.new(
            type: 'array',
            items: {
              type: 'string',
              existence: true
            },
            content_type: 'application/json-seq',
            existence: true
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  schema: {
                    type: 'array',
                    items: { type: 'string' }
                  }
                }
              when OpenAPI::V3_0, OpenAPI::V3_1
                {
                  content: {
                    'application/json-seq' => {
                      schema: {
                        type: 'array',
                        items: { type: 'string' }
                      }
                    }
                  }
                }
              else
                {
                  content: {
                    'application/json-seq' => {
                      itemSchema: {
                        type: 'string'
                      }
                    }
                  }
                }
              end,
              response,
              version,
              nil
            )
          end
        end
      end
    end
  end
end
