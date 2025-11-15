# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class OperationTest < Minitest::Test
      include OpenAPITestHelper

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

      def test_parameters
        operation = Operation.new('foo')
        parameter = operation.add_parameter('bar', type: 'string')
        assert(parameter.equal?(operation.parameter('bar')))
      end

      def test_responses
        operation = Operation.new('foo')
        default_response = operation.add_response(type: 'string')
        not_found_response = operation.add_response(404, type: 'string')

        assert(default_response.equal?(operation.response))
        assert(not_found_response.equal?(operation.response(404)))
      end

      def test_resolved_parameters
        parameters = Operation.new(
          nil,
          '/foo',
          parameters: {
            'bar' => { type: 'string' }
          }
        ).resolved_parameters(
          Definitions.new(
            paths: {
              '/foo' => {
                parameters: {
                  'foo' => { type: 'string' }
                }
              }
            }
          )
        )
        assert_equal(%w[bar foo], parameters.keys.sort)
      end

      def test_resolved_parameters_on_references
        parameters = Operation.new(
          nil,
          '/foo',
          parameters: {
            'bar' => { ref: 'bar' }
          }
        ).resolved_parameters(
          Definitions.new(
            parameters: {
              'foo' => { type: 'string' },
              'bar' => { type: 'string' }
            },
            paths: {
              '/foo' => {
                parameters: {
                  'foo' => { ref: 'foo' }
                }
              }
            }
          )
        )
        assert_equal(%w[bar foo], parameters.keys.sort)
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
            nil => {
              type: 'string'
            }
          },
          callbacks: {
            'onBar' => {
              operations: {
                '{$request.query.bar}' => {}
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
                produces: [
                  'application/json'
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
                    content: {
                      'application/json' => {
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
                    content: {
                      'application/json' => {
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
    end
  end
end
