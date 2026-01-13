# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class OperationTest < Minitest::Test
      include TestHelper

      def test_add_parameter
        operation = Operation.new('foo')
        parameter = operation.add_parameter('bar', type: 'string')
        assert(parameter.equal?(operation.parameter('bar')))
      end

      def test_add_parameter_raises_an_error_when_frozen
        operation = Operation.new('foo')
        operation.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          operation.add_parameter('bar')
        end
      end

      def test_full_path
        operation = Operation.new(nil)
        assert_equal(Pathname.new, operation.full_path)

        operation = Operation.new(nil, 'foo')
        assert_equal(Pathname.new('foo'), operation.full_path)

        operation = Operation.new(nil, path: 'foo')
        assert_equal(Pathname.new('foo'), operation.full_path)

        operation = Operation.new(nil, 'foo', path: 'bar')
        assert_equal(Pathname.new('foo/bar'), operation.full_path)
      end

      # OpenAPI objects

      def test_minimal_openapi_operation_object
        operation = Operation.new('foo')

        each_openapi_version do |version|
          assert_openapi_equal(
            {
              operationId: 'foo',
              parameters: [],
              responses: {}
            },
            operation,
            version,
            Definitions.new
          )
        end
      end

      def test_full_openapi_operation_object
        operation = Operation.new(
          'foo',
          tags: %w[Foo],
          summary: 'Summary of foo',
          description: 'Lorem ipsum',
          external_docs: {
            url: 'https://foo.bar/docs'
          },
          parameters: {
            'bar' => {
              type: 'string',
              in: 'query'
            }
          },
          request_body: {
            type: 'string',
            existence: true
          },
          responses: {
            'default' => {
              contents: {
                'application/json' => {
                  type: 'string'
                },
                'text/plain' => {
                  type: 'string'
                }
              }
            },
            '4xx' => {
              contents: {
                'application/problem+json' => {
                  type: 'string'
                }
              }
            }
          },
          callbacks: {
            'onBar' => {
              expressions: {
                '{$request.query.bar}' => {
                  operations: {
                    'get' => {}
                  }
                }
              }
            }
          },
          security_requirements: {
            schemes: {
              'http_basic' => {}
            }
          },
          deprecated: true,
          schemes: %w[https],
          servers: [
            { url: 'https://foo.bar/foo' }
          ],
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            case version
            when OpenAPI::V2_0
              {
                operationId: 'foo',
                tags: %w[Foo],
                summary: 'Summary of foo',
                description: 'Lorem ipsum',
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                consumes: [
                  'application/json'
                ],
                produces: %w[
                  application/json
                ],
                parameters: [
                  {
                    name: 'bar',
                    in: 'query',
                    type: 'string',
                    allowEmptyValue: true
                  },
                  {
                    name: 'body',
                    in: 'body',
                    required: true,
                    type: 'string'
                  }
                ],
                responses: {
                  'default' => {
                    schema: {
                      type: 'string'
                    }
                  }
                },
                schemes: %w[https],
                deprecated: true,
                security: [
                  { 'http_basic' => [] }
                ],
                'x-foo': 'bar'
              }
            when OpenAPI::V3_0
              {
                operationId: 'foo',
                tags: %w[Foo],
                summary: 'Summary of foo',
                description: 'Lorem ipsum',
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                parameters: [
                  {
                    name: 'bar',
                    in: 'query',
                    schema: {
                      type: 'string',
                      nullable: true
                    },
                    allowEmptyValue: true
                  }
                ],
                request_body: {
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'string'
                      }
                    }
                  },
                  required: true
                },
                responses: {
                  'default' => {
                    content: %w[application/json text/plain].index_with do
                      {
                        schema: {
                          type: 'string',
                          nullable: true
                        }
                      }
                    end
                  },
                  '4XX' => {
                    content: {
                      'application/problem+json' => {
                        schema: {
                          type: 'string',
                          nullable: true
                        }
                      }
                    }
                  }
                },
                callbacks: {
                  'onBar' => {
                    '{$request.query.bar}' => {
                      'get' => {
                        parameters: [],
                        responses: {}
                      }
                    }
                  }
                },
                deprecated: true,
                security: [
                  { 'http_basic' => [] }
                ],
                servers: [
                  { url: 'https://foo.bar/foo' }
                ],
                'x-foo': 'bar'
              }
            else
              {
                operationId: 'foo',
                tags: %w[Foo],
                summary: 'Summary of foo',
                description: 'Lorem ipsum',
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                parameters: [
                  {
                    name: 'bar',
                    in: 'query',
                    schema: {
                      type: %w[string null]
                    },
                    allowEmptyValue: true
                  }
                ],
                request_body: {
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'string'
                      }
                    }
                  },
                  required: true
                },
                responses: {
                  'default' => {
                    content: %w[application/json text/plain].index_with do
                      {
                        schema: {
                          type: %w[string null]
                        }
                      }
                    end
                  },
                  '4XX' => {
                    content: {
                      'application/problem+json' => {
                        schema: {
                          type: %w[string null]
                        }
                      }
                    }
                  }
                },
                callbacks: {
                  'onBar' => {
                    '{$request.query.bar}' => {
                      'get' => {
                        parameters: [],
                        responses: {}
                      }
                    }
                  }
                },
                deprecated: true,
                security: [
                  { 'http_basic' => [] }
                ],
                servers: [
                  { url: 'https://foo.bar/foo' }
                ],
                'x-foo': 'bar'
              }
            end,
            operation,
            version,
            Definitions.new
          )
        end
      end

      def test_openapi_operation_object_with_empty_security_array
        operation = Operation.new('foo', security_requirements: [])

        each_openapi_version do |version|
          assert_openapi_equal(
            {
              operationId: 'foo',
              parameters: [],
              responses: {},
              security: []
            },
            operation,
            version,
            Definitions.new
          )
        end
      end

      def test_openapi_operation_object_with_path_defaults
        operation = Operation.new(
          'foo',
          path: '/bar',
          tags: %w[Foo]
        )
        definitions = Definitions.new(
          paths: {
            '/bar' => {
              responses: {
                'default' => {
                  type: 'string',
                  existence: true
                }
              },
              security_requirements: [
                { schemes: { 'http_basic' => nil } }
              ],
              tags: %w[Bar]
            }
          }
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            if version == OpenAPI::V2_0
              {
                operationId: 'foo',
                produces: %w[application/json],
                parameters: [],
                responses: {
                  'default' => {
                    schema: {
                      type: 'string'
                    }
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: %w[Foo Bar]
              }
            else
              {
                operationId: 'foo',
                parameters: [],
                responses: {
                  'default' => {
                    content: {
                      'application/json' => {
                        schema: {
                          type: 'string'
                        }
                      }
                    }
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: %w[Foo Bar]
              }
            end,
            operation,
            version,
            definitions
          )
        end
      end

      def test_to_openapi_skips_responses_not_to_be_documented
        operation = Operation.new(
          nil,
          responses: {
            'default' => {
              content_type: 'application/json'
            },
            '5xx' => {
              content_type: 'application/problem+json',
              nodoc: true
            }
          }
        )
        definitions = Definitions.new

        each_openapi_version do |version|
          openapi_operation_object = operation.to_openapi(version, definitions).as_json

          if version == OpenAPI::V2_0
            assert_equal(
              %w[application/json],
              openapi_operation_object['produces']
            )
          end

          assert_equal(%w[default], openapi_operation_object['responses'].keys)
        end
      end

      def test_to_openapi_skips_response_references_not_to_be_documented
        operation = Operation.new(
          nil,
          responses: {
            '404' => {
              ref: 'error'
            },
            '5xx' => {
              ref: 'error',
              nodoc: true
            }
          }
        )
        definitions = Definitions.new(
          responses: {
            'error' => {
              content_type: 'application/problem+json'
            }
          }
        )
        each_openapi_version do |version|
          openapi_operation_object = operation.to_openapi(version, definitions).as_json

          assert_equal(%w[404], openapi_operation_object['responses'].keys)
        end
      end
    end
  end
end
