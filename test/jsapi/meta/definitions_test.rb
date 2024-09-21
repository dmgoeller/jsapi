# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class DefinitionsTest < Minitest::Test
      # #ancestors

      def test_ancestors
        base_definitions1 = Definitions.new(
          owner: 'base 1'
        )
        base_definitions2 = Definitions.new(
          owner: 'base 2',
          parent: base_definitions1
        )
        included_definitions1 = Definitions.new(
          owner: 'included 1'
        )
        included_definitions2 = Definitions.new(
          owner: 'included 2',
          parent: included_definitions1
        )
        definitions = Definitions.new(
          owner: 'definitions',
          parent: base_definitions2,
          included: [included_definitions1, included_definitions2]
        )
        assert_equal(
          [base_definitions1],
          base_definitions1.ancestors
        )
        assert_equal(
          [base_definitions2, base_definitions1],
          base_definitions2.ancestors
        )
        assert_equal(
          [definitions, included_definitions1, included_definitions2,
           base_definitions2, base_definitions1],
          definitions.ancestors
        )
      end

      # Inclusion

      def test_detects_circular_dependencies
        definitions1 = Definitions.new(owner: 'definitions 1')
        definitions2 = Definitions.new(owner: 'definitions 2', included: definitions1)
        definitions3 = Definitions.new(owner: 'definitions 3', included: definitions2)

        error = assert_raises(ArgumentError) { definitions1.add_included(definitions3) }
        assert_equal(
          'detected circular dependency between "definitions 1" and "definitions 3"',
          error.message
        )
      end

      def test_would_not_raise_an_exception_when_including_parent
        base_definitions = Definitions.new

        definitions = Definitions.new(parent: base_definitions)
        definitions.add_included(base_definitions)

        assert_equal([definitions, base_definitions], definitions.ancestors)
      end

      # Components

      def test_add_parameter
        definitions = Definitions.new
        definitions.add_parameter('foo')
        assert(definitions.parameters.key?('foo'))
      end

      def test_find_component
        definitions = Definitions.new
        assert_nil(definitions.find_component(:schema, nil))
        assert_nil(definitions.find_component(:schema, 'foo'))

        schema = definitions.add_schema('foo')
        assert_equal(schema, definitions.find_component(:schema, 'foo'))
      end

      def test_find_component_on_inheritance
        base_definitions = Definitions.new
        schema = base_definitions.add_schema('foo')

        definitions = Definitions.new(parent: base_definitions)
        assert_equal(schema, definitions.find_component(:schema, 'foo'))
      end

      def test_find_component_on_inclusion
        included_definitions = Definitions.new
        schema = included_definitions.add_schema('foo')

        definitions = Definitions.new(included: [included_definitions])
        assert_equal(schema, definitions.find_component(:schema, 'foo'))
      end

      # Operations

      def test_add_operation
        definitions = Definitions.new
        definitions.add_operation('foo')
        assert(definitions.operations.key?('foo'))
      end

      def test_find_operation
        definitions = Definitions.new
        assert_nil(definitions.find_operation(nil))

        definitions.add_operation('foo')
        assert_equal('foo', definitions.find_operation.name)
        assert_equal('foo', definitions.find_operation('foo').name)
      end

      def test_default_operation_name_and_path
        definitions = Definitions.new(owner: 'Foo::Bar::FooBarController')
        operation = definitions.add_operation
        assert_equal('foo_bar', operation.name)
        assert_equal('/foo_bar', operation.path)
      end

      # #rescue_handler_for

      def test_rescue_handler_for
        definitions = Definitions.new(
          rescue_handlers: [
            {
              error_class: Controller::ParametersInvalid,
              status: 400
            },
            {
              error_class: StandardError,
              status: 500
            }
          ]
        )
        assert_equal(
          400,
          definitions.rescue_handler_for(
            Controller::ParametersInvalid.new(Model::Base.new({}))
          ).status
        )
        assert_equal(
          500,
          definitions.rescue_handler_for(StandardError.new).status
        )
        assert_nil(definitions.rescue_handler_for(Exception.new))
      end

      # #default_value

      def test_default_value
        definitions = Definitions.new(
          defaults: {
            'array' => { within_requests: [] }
          }
        )
        assert_equal([], definitions.default_value('array', context: :request))
      end

      def test_default_value_returns_nil_by_default
        definitions = Definitions.new
        assert_nil(definitions.default_value(nil))
        assert_nil(definitions.default_value('array'))
      end

      # JSON Schema documents

      def test_json_schema_document
        definitions = Definitions.new(
          schemas: {
            'Foo' => {
              properties: {
                'bar' => { type: 'string' }
              }
            },
            'Bar' => {
              properties: {
                'foo' => { schema: 'Foo' }
              }
            }
          }
        )
        # 'Foo'
        assert_equal(
          {
            type: %w[object null],
            properties: {
              'bar' => {
                type: %w[string null]
              }
            },
            required: [],
            definitions: {
              'Bar' => {
                type: %w[object null],
                properties: {
                  'foo' => {
                    '$ref': '#/definitions/Foo'
                  }
                },
                required: []
              }
            }
          },
          definitions.json_schema_document('Foo')
        )

        # 'Bar'
        assert_equal(
          {
            type: %w[object null],
            properties: {
              'foo' => {
                '$ref': '#/definitions/Foo'
              }
            },
            required: [],
            definitions: {
              'Foo' => {
                type: %w[object null],
                properties: {
                  'bar' => {
                    type: %w[string null]
                  }
                },
                required: []
              }
            }
          },
          definitions.json_schema_document('Bar')
        )

        # Others
        assert_nil(definitions.json_schema_document('FooBar'))
      end

      def test_json_schema_document_without_definitions
        definitions = Definitions.new(
          schemas: {
            'Foo' => {
              properties: {
                'bar': { type: 'string' }
              }
            }
          }
        )
        assert_equal(
          {
            type: %w[object null],
            properties: {
              'bar' => {
                type: %w[string null]
              }
            },
            required: []
          },
          definitions.json_schema_document('Foo')
        )
      end

      # OpenAPI documents

      def test_empty_openapi_document
        definitions = Definitions.new
        %w[2.0 3.0 3.1].each do |version|
          assert_equal({}, definitions.openapi_document(version))
        end
      end

      def test_full_openapi_document
        definitions = Definitions.new(
          openapi: {
            info: { title: 'Foo', version: '1' }
          },
          operations: {
            'operation' => {
              path: '/bar',
              method: 'post',
              parameters: {
                'parameter': { ref: 'parameter' }
              },
              request_body: { ref: 'request_body' },
              responses: {
                200 => { ref: 'response' },
                400 => { ref: 'error_response' }
              }
            }
          },
          request_bodies: {
            'request_body' => { type: 'string' }
          },
          parameters: {
            'parameter' => { type: 'string' }
          },
          responses: {
            'response' => { schema: 'response_schema' },
            'error_response' => {
              type: 'string',
              content_type: 'application/problem+json'
            }
          },
          schemas: {
            'response_schema' => { type: 'object' }
          }
        )
        # OpenAPI 2.0
        assert_equal(
          {
            swagger: '2.0',
            info: {
              title: 'Foo',
              version: '1'
            },
            consumes: %w[application/json],
            produces: %w[application/json application/problem+json],
            paths: {
              '/bar' => {
                'post' => {
                  operationId: 'operation',
                  consumes: %w[application/json],
                  produces: %w[application/json application/problem+json],
                  parameters: [
                    {
                      '$ref': '#/parameters/parameter'
                    },
                    {
                      name: 'body',
                      in: 'body',
                      required: false,
                      type: 'string'
                    }
                  ],
                  responses: {
                    '200' => {
                      '$ref': '#/responses/response'
                    },
                    '400' => {
                      '$ref': '#/responses/error_response'
                    }
                  }
                }
              }
            },
            definitions: {
              'response_schema' => {
                type: 'object',
                properties: {},
                required: []
              }
            },
            parameters: {
              'parameter' => {
                name: 'parameter',
                in: 'query',
                type: 'string',
                allowEmptyValue: true
              }
            },
            responses: {
              'response' => {
                schema: {
                  '$ref': '#/definitions/response_schema'
                }
              },
              'error_response' => {
                schema: {
                  type: 'string'
                }
              }
            }
          },
          definitions.openapi_document('2.0')
        )
        # OpenAPI 3.0
        assert_equal(
          {
            openapi: '3.0.3',
            info: {
              title: 'Foo',
              version: '1'
            },
            paths: {
              '/bar' => {
                'post' => {
                  operationId: 'operation',
                  parameters: [
                    {
                      '$ref': '#/components/parameters/parameter'
                    }
                  ],
                  request_body: {
                    '$ref': '#/components/requestBodies/request_body'
                  },
                  responses: {
                    '200' => {
                      '$ref': '#/components/responses/response'
                    },
                    '400' => {
                      '$ref': '#/components/responses/error_response'
                    }
                  }
                }
              }
            },
            components: {
              schemas: {
                'response_schema' => {
                  type: 'object',
                  nullable: true,
                  properties: {},
                  required: []
                }
              },
              parameters: {
                'parameter' => {
                  name: 'parameter',
                  in: 'query',
                  schema: {
                    type: 'string',
                    nullable: true
                  },
                  allowEmptyValue: true
                }
              },
              requestBodies: {
                'request_body' => {
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'string',
                        nullable: true
                      }
                    }
                  },
                  required: false
                }
              },
              responses: {
                'response' => {
                  content: {
                    'application/json' => {
                      schema: {
                        '$ref': '#/components/schemas/response_schema'
                      }
                    }
                  }
                },
                'error_response' => {
                  content: {
                    'application/problem+json' => {
                      schema: {
                        type: 'string',
                        nullable: true
                      }
                    }
                  }
                }
              }
            }
          },
          definitions.openapi_document('3.0')
        )
      end

      # # inspect

      def test_inspect
        definitions = Definitions.new(
          owner: 'foo',
          parent: Definitions.new(owner: 'base'),
          included: [Definitions.new(owner: 'incl')]
        )
        assert_equal(
          '#<Jsapi::Meta::Definitions owner: "foo", ' \
          'parent: #<Jsapi::Meta::Definitions owner: "base", parent: nil, included: []>, ' \
          'included: [#<Jsapi::Meta::Definitions owner: "incl", parent: nil, included: []>]>',
          definitions.inspect
        )
      end
    end
  end
end
