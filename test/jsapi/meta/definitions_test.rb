# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class DefinitionsTest < Minitest::Test
      include TestHelper

      # Inheritance and inclusion

      def test_ancestors
        base1 = Definitions.new
        base2 = Definitions.new(parent: base1)

        included1 = Definitions.new
        included2 = Definitions.new(parent: included1)

        definitions = Definitions.new(parent: base2, include: [included2, included1])

        assert_equal([base1], base1.ancestors)
        assert_equal([base2, base1], base2.ancestors)
        assert_equal([definitions, included2, included1, base2, base1], definitions.ancestors)
      end

      def test_inheritance
        definitions = Definitions.new(
          parent: parent = Definitions.new(
            schemas: {
              foo: {},
              bar: {}
            }
          ),
          schemas: {
            foo: {}
          }
        )
        foo = definitions.find_schema('foo')
        assert_predicate(foo, :present?)
        assert(!foo.equal?(parent.find_schema('foo')))

        bar = definitions.find_schema('bar')
        assert_predicate(bar, :present?)
        assert(bar.equal?(parent.find_schema('bar')))
      end

      def test_include_raises_an_error_on_circular_dependency
        definitions = (1..3).map { |i| Definitions.new(owner: i) }

        definitions.second.include(definitions.first)
        definitions.third.include(definitions.second)

        error = assert_raises(ArgumentError) do
          definitions.first.include(definitions.third)
        end
        assert_equal('detected circular dependency between 1 and 3', error.message)
      end

      def test_include_does_not_raise_an_exception_when_including_parent
        base_definitions = Definitions.new

        definitions = Definitions.new(parent: base_definitions)
        definitions.include(base_definitions)

        assert_equal([definitions, base_definitions], definitions.ancestors)
      end

      # Operations

      def test_add_operation
        definitions = Definitions.new
        operation = definitions.add_operation('foo')
        assert(operation.equal?(definitions.operation('foo')))
      end

      def test_add_operation_with_parent_path
        definitions = Definitions.new
        operation = definitions.add_operation('foo', 'bar')
        assert_equal(Pathname.new('/bar'), operation.parent_path)
      end

      def test_add_operation_raises_an_error_when_frozen
        definitions = Definitions.new
        definitions.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          definitions.add_operation('foo')
        end
      end

      def test_default_operation_name
        definitions = Definitions.new(
          owner: Struct.new(:name).new('Foo::Bar::FooBarController')
        )
        operation = definitions.add_operation nil
        assert_equal('foo_bar', operation.name)
      end

      def test_default_parent_path
        definitions = Definitions.new(
          owner: Struct.new(:name).new('Foo::Bar::FooBarController')
        )
        operation = definitions.add_operation nil
        assert_equal(Pathname.new('/foo_bar'), operation.parent_path)

        operation = definitions.add_operation nil, path: 'foo'
        assert_equal(Pathname.new, operation.parent_path)
      end

      def test_find_operation
        definitions = Definitions.new
        assert_nil(definitions.find_operation(nil))

        definitions.add_operation('foo')

        operation = definitions.find_operation
        assert_kind_of(Operation::Wrapper, operation)
        assert_equal('foo', operation.name)

        operation = definitions.find_operation('foo')
        assert_kind_of(Operation::Wrapper, operation)
        assert_equal('foo', operation.name)
      end

      def test_operation_caching
        definitions = Definitions.new(operations: { 'foo' => {} })

        # Make cached operations accessible
        definitions.define_singleton_method(:__cached_operations__) do
          @cache&.fetch(:operations, nil)
        end

        assert(
          definitions.__cached_operations__.blank?,
          'Expected no operations to be cached initially.'
        )
        # Look up operation
        operation = definitions.find_operation('foo')
        assert(
          definitions.__cached_operations__['foo'].present?,
          'Expected operation to be cached.'
        )
        assert(
          operation.equal?(definitions.find_operation('foo')),
          'Expected cached operation to be returned.'
        )
        # Add another operation
        definitions.add_operation('bar')
        assert(
          definitions.__cached_operations__.blank?,
          'Expected cached operations to be invalidated.'
        )
        # Look up operation again
        operation = definitions.find_operation('foo')
        assert(
          definitions.__cached_operations__['foo'].present?,
          'Expected operation to be cached again.'
        )
        assert(
          operation.equal?(definitions.find_operation('foo')),
          'Expected cached operation to be returned.'
        )
      end

      # Paths

      def test_add_path
        definitions = Definitions.new
        path = definitions.add_path('foo')

        assert(path.equal?(definitions.path('foo')))
        assert_equal(Pathname.new('foo'), path.name)
      end

      def test_add_path_raises_an_error_when_frozen
        definitions = Definitions.new
        definitions.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          definitions.add_path('foo')
        end
      end

      %i[description summary].each do |name|
        method_name = :"common_#{name}"

        define_method("test_#{method_name}") do
          definitions = Definitions.new(
            paths: {
              '/foo' => {
                name => 'Lorem ipsum'
              }
            }
          )
          assert_equal('Lorem ipsum', definitions.send(method_name, '/foo'))
          assert_nil(definitions.send(method_name, '/bar'))
          assert_nil(definitions.send(method_name, nil))
        end

        define_method("test_#{method_name}_on_inheritance") do
          definitions = Definitions.new(
            parent: Definitions.new(
              paths: {
                '/foo' => {
                  name => 'Lorem ipsum'
                }
              }
            ),
            paths: {
              '/foo' => {}
            }
          )
          assert_equal('Lorem ipsum', definitions.send(method_name, '/foo'))
        end
      end

      def test_common_model
        definitions = Definitions.new(
          paths: {
            '/foo' => { model: model = Class.new },
            'foo/bar' => {}
          }
        )
        assert_equal(model, definitions.common_model('/foo/bar'))
        assert_equal(model, definitions.common_model('/foo'))
        assert_nil(definitions.common_model('/bar'))
        assert_nil(definitions.common_model(nil))
      end

      def test_common_model_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => { model: model = Class.new }
            }
          ),
          paths: {
            'foo/bar' => {}
          }
        )
        assert_equal(model, definitions.common_model('/foo/bar'))
        assert_equal(model, definitions.common_model('/foo'))
        assert_nil(definitions.common_model('/bar'))
        assert_nil(definitions.common_model(nil))
      end

      def test_common_model_caching
        assert_path_attribute_caching(:model) do |path|
          path.model = Class.new
        end
      end

      def test_common_parameters
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              parameters: {
                'foo' => { type: 'string' }
              }
            },
            'foo/bar' => {
              parameters: {
                'bar' => { type: 'string' }
              }
            }
          }
        )
        assert_equal(%w[foo bar], definitions.common_parameters('/foo/bar').keys)
        assert_equal(%w[foo], definitions.common_parameters('/foo').keys)
        assert_nil(definitions.common_parameters('/bar'))
        assert_nil(definitions.common_parameters(nil))
      end

      def test_common_parameters_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => {
                parameters: {
                  'foo' => { type: 'string' }
                }
              }
            }
          ),
          paths: {
            '/foo/bar' => {
              parameters: {
                'bar' => { type: 'string' }
              }
            }
          }
        )
        assert_equal(%w[foo bar], definitions.common_parameters('/foo/bar').keys)
        assert_equal(%w[foo], definitions.common_parameters('/foo').keys)
      end

      def test_common_parameters_caching
        assert_path_attribute_caching(:parameters) do |path|
          path.add_parameter 'foo', type: 'string'
        end
      end

      def test_common_request_body
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              request_body: {}
            },
            '/foo/bar' => {}
          }
        )
        request_body = definitions.common_request_body('/foo')
        assert_predicate request_body, :present?
        assert_equal(request_body, definitions.common_request_body('/foo/bar'))

        assert_nil(definitions.common_request_body('/bar'))
        assert_nil(definitions.common_request_body(nil))
      end

      def test_common_request_body_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => {
                request_body: {}
              }
            }
          ),
          paths: {
            'foo/bar' => {}
          }
        )
        request_body = definitions.common_request_body('/foo')
        assert_predicate request_body, :present?

        assert_equal(request_body, definitions.common_request_body('/foo/bar'))
      end

      def test_common_request_body_caching
        assert_path_attribute_caching(:request_body) do |path|
          path.request_body = { type: 'string' }
        end
      end

      def test_common_responses
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              responses: {
                '4xx' => { type: 'string' }
              }
            },
            'foo/bar' => {
              responses: {
                'default' => { type: 'string' }
              }
            }
          }
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR, Status::DEFAULT],
          definitions.common_responses('/foo/bar').keys
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR],
          definitions.common_responses('/foo').keys
        )
        assert_nil(definitions.common_responses('/bar'))
        assert_nil(definitions.common_responses(nil))
      end

      def test_common_responses_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => {
                responses: {
                  '4xx' => { type: 'string' }
                }
              }
            }
          ),
          paths: {
            '/foo/bar' => {
              responses: {
                'default' => { type: 'string' }
              }
            }
          }
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR, Status::DEFAULT],
          definitions.common_responses('/foo/bar').keys
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR],
          definitions.common_responses('/foo').keys
        )
      end

      def test_common_responses_caching
        assert_path_attribute_caching(:responses) do |path|
          path.add_response nil, type: 'string'
        end
      end

      def test_common_security_requirements
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              security_requirements: [
                { schemes: { 'foo' => nil } }
              ]
            },
            '/foo/bar' => {
              security_requirements: [
                { schemes: { 'bar' => nil } }
              ]
            }
          }
        )
        { '/foo' => %w[foo], 'foo/bar' => %w[bar foo] }.each do |pathname, expected|
          assert_equal(
            expected,
            definitions.common_security_requirements(pathname).flat_map { |s| s.schemes.keys }
          )
        end
        assert_nil(definitions.common_security_requirements('/bar'))
        assert_nil(definitions.common_security_requirements(nil))
      end

      def test_common_security_requirements_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => {
                security_requirements: [
                  { schemes: { 'foo' => nil } }
                ]
              }
            }
          ),
          paths: {
            '/foo/bar' => {
              security_requirements: [
                { schemes: { 'bar' => nil } }
              ]
            }
          }
        )
        { '/foo' => %w[foo], 'foo/bar' => %w[bar foo] }.each do |pathname, expected|
          assert_equal(
            expected,
            definitions.common_security_requirements(pathname).flat_map { |s| s.schemes.keys }
          )
        end
      end

      def test_common_security_requirements_caching
        assert_path_attribute_caching(:security_requirements) do |path|
          path.add_security_requirement(schemes: {})
        end
      end

      def test_common_servers
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              servers: [
                { url: 'https://foo.bar/foo' }
              ]
            }
          }
        )
        assert_equal(%w[https://foo.bar/foo], definitions.common_servers('/foo').map(&:url))
        assert_nil(definitions.common_servers('bar'))
        assert_nil(definitions.common_servers(nil))
      end

      def test_common_servers_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => {
                servers: [
                  { url: 'https://foo.bar/foo' }
                ]
              }
            }
          ),
          paths: {
            '/foo' => {}
          }
        )
        assert_equal(%w[https://foo.bar/foo], definitions.common_servers('/foo').map(&:url))
      end

      def test_common_servers_caching
        assert_path_attribute_caching(:servers) do |path|
          path.add_server(url: 'https://foo.bar/foo')
        end
      end

      def test_common_tags
        definitions = Definitions.new(
          paths: {
            '/foo' => { tags: %w[Foo] },
            '/foo/bar' => { tags: %w[Bar] }
          }
        )
        assert_equal(%w[Foo], definitions.common_tags('/foo'))
        assert_equal(%w[Bar Foo], definitions.common_tags('/foo/bar'))
        assert_nil(definitions.common_tags('/bar'))
        assert_nil(definitions.common_tags(nil))
      end

      def test_common_tags_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            paths: {
              '/foo' => { tags: %w[Foo] }
            }
          ),
          paths: {
            '/foo/bar' => { tags: %w[Bar] }
          }
        )
        assert_equal(%w[Foo], definitions.common_tags('/foo'))
        assert_equal(%w[Bar Foo], definitions.common_tags('/foo/bar'))
      end

      def test_common_tags_caching
        assert_path_attribute_caching(:tags) do |path|
          path.add_tag('Foo')
        end
      end

      # Components

      %i[parameter request_body response schema].each do |name|
        plural_name = name.to_s.pluralize.to_sym

        define_method("test_add_and_find_#{name}") do
          definitions = Definitions.new
          schema = definitions.send(:"add_#{name}", 'foo')

          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
          assert_nil(definitions.send(:"find_#{name}", nil))
        end

        define_method("test_add_#{name}_raises_an_error_when_frozen") do
          definitions = Definitions.new
          definitions.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            definitions.send(:"add_#{name}", 'foo')
          end
        end

        define_method("test_find_#{name}_on_inheritance") do
          base_definitions = Definitions.new
          schema = base_definitions.send(:"add_#{name}", 'foo')

          definitions = Definitions.new(parent: base_definitions)
          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
        end

        define_method("test_find_#{name}_on_inclusion") do
          included_definitions = Definitions.new
          schema = included_definitions.send(:"add_#{name}", 'foo')

          definitions = Definitions.new(include: [included_definitions])
          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
        end

        define_method("test_#{name}_caching") do
          definitions = Definitions.new(
            parent: parent = Definitions.new({ plural_name => {} }),
            plural_name => { 'foo' => {} }
          )
          # Make cached attributes accessible
          definitions.define_singleton_method(:__cached_attributes__) do
            @cache&.fetch(:attributes, nil)
          end

          assert(
            definitions.__cached_attributes__.blank?,
            'Expected no attributes to be cached initially.'
          )
          # Query attribute
          definitions.send(:"find_#{name}", 'foo')
          assert(
            definitions.__cached_attributes__[plural_name].keys == %w[foo],
            "Expected \"#{name}\" attribute to be cached."
          )
          # Modify attribute
          definitions.send(:"add_#{name}", 'bar')
          assert(
            definitions.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after an ' \
            'attribute has been modified.'
          )
          # Query attribute again
          definitions.send(:"find_#{name}", 'foo')
          assert(
            definitions.__cached_attributes__[plural_name].keys.sort == %w[bar foo],
            "Expected \"#{name}\" attribute to be cached (2)."
          )
          # Modify attribute in parent definitions
          parent.send(:"add_#{name}", 'bar')
          assert(
            definitions.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after an ' \
            'attribute of parent definitions has been modified.'
          )
          # Query attribute again
          definitions.send(:"find_#{name}", 'foo')
          assert(
            definitions.__cached_attributes__[plural_name].keys.sort == %w[bar foo],
            "Expected \"#{name}\" attribute to be cached (3)."
          )
          # Include another instance
          definitions.include(
            Definitions.new(
              plural_name => {
                'baz' => {}
              }
            )
          )
          assert(
            definitions.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after another ' \
            'Definitions instance has been included.'
          )
          # Query attribute again
          definitions.send(:"find_#{name}", 'foo')
          assert(
            definitions.__cached_attributes__[plural_name].keys.sort == %w[bar baz foo],
            "Expected \"#{name}\" attribute to be cached (4)."
          )
        end
      end

      # Security requirements

      def test_default_security_requirements
        security_requirements = Definitions.new(
          parent: Definitions.new(
            security_requirements: [
              { schemes: { 'bar' => nil } }
            ]
          ),
          security_requirements: [
            { schemes: { 'foo' => nil } }
          ]
        ).default_security_requirements

        assert_equal(
          %w[foo bar],
          security_requirements.flat_map { |s| s.schemes.keys }
        )
      end

      # Rescue handlers

      def test_rescue_handler_for
        bad_request = Class.new(StandardError)

        definitions = Definitions.new(
          rescue_handlers: [
            {
              error_class: bad_request,
              status_code: 400
            },
            {
              error_class: StandardError,
              status_code: 500
            }
          ]
        )
        assert_equal(
          Status::Code.from(400),
          definitions.rescue_handler_for(bad_request.new).status_code
        )
        assert_equal(
          Status::Code.from(500),
          definitions.rescue_handler_for(StandardError.new).status_code
        )
        assert_nil(definitions.rescue_handler_for(Exception.new))
      end

      # Default values

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
        assert_json_equal(
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
        assert_json_equal(
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
        assert_json_equal(nil, definitions.json_schema_document('FooBar'))
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
        assert_json_equal(
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

      def test_minimal_openapi_document
        definitions = Definitions.new

        each_openapi_version do |version|
          assert_openapi_equal(
            case version
            when OpenAPI::V2_0
              { swagger: '2.0' }
            when OpenAPI::V3_0
              { openapi: '3.0.4' }
            when OpenAPI::V3_1
              { openapi: '3.1.2' }
            when OpenAPI::V3_2
              { openapi: '3.2.0' }
            end,
            definitions,
            version,
            method: :openapi_document
          )
        end
      end

      def test_full_openapi_document
        definitions = Definitions.new(
          base_path: '/foo',
          callbacks: {
            'onFoo' => {
              expressions: {
                '{$request.query.foo}' => {
                  operations: {
                    'get' => {}
                  }
                }
              }
            }
          },
          examples: {
            'foo' => { value: 'bar' }
          },
          external_docs: { url: 'https://foo.bar/docs' },
          headers: {
            'X-Foo' => { type: 'string' }
          },
          host: 'https://foo.bar',
          info: { title: 'Foo', version: '1' },
          links: {
            'foo' => { operation_id: 'foo' }
          },
          openapi_extensions: { 'foo' => 'bar' },
          paths: {
            '/bar' => {
              servers: [
                { url: 'http:s//foo.baz' }
              ],
              parameters: {
                'common_parameter' => {
                  type: :string,
                  existence: true
                }
              }
            }
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
            },
            'additional_operation' => {
              path: '/bar',
              method: 'CUSTOM'
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
          },
          schemes: %w[https],
          security_requirements: {
            schemes: { 'http_basic': nil }
          },
          security_schemes: {
            'http_basic' => { type: 'basic' }
          },
          servers: [
            { url: 'https://foo.bar/foo' }
          ],
          tags: [
            { name: 'Foo' }
          ]
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            case version
            when OpenAPI::V2_0
              {
                swagger: '2.0',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                host: 'https://foo.bar',
                basePath: '/foo',
                schemes: %w[https],
                consumes: %w[application/json],
                produces: %w[application/json application/problem+json],
                paths: {
                  '/bar' => {
                    'post' => {
                      operationId: 'operation',
                      consumes: %w[application/json],
                      produces: %w[application/json application/problem+json],
                      parameters: [
                        { '$ref': '#/parameters/parameter' },
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
                    },
                    parameters: [
                      {
                        name: 'common_parameter',
                        in: 'query',
                        type: 'string',
                        required: true
                      }
                    ]
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
                },
                securityDefinitions: {
                  'http_basic' => {
                    type: 'basic'
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: [
                  { name: 'Foo' }
                ],
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                'x-foo': 'bar'
              }
            when OpenAPI::V3_0
              {
                openapi: '3.0.4',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                servers: [
                  { url: 'https://foo.bar/foo' }
                ],
                paths: {
                  '/bar' => {
                    'post' => {
                      operationId: 'operation',
                      parameters: [
                        { '$ref': '#/components/parameters/parameter' }
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
                    },
                    servers: [
                      { url: 'http:s//foo.baz' }
                    ],
                    parameters: [
                      {
                        name: 'common_parameter',
                        in: 'query',
                        schema: {
                          type: 'string'
                        },
                        required: true
                      }
                    ]
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
                  examples: {
                    'foo' => {
                      value: 'bar'
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
                  headers: {
                    'X-Foo' => {
                      schema: {
                        type: 'string',
                        nullable: true
                      }
                    }
                  },
                  securitySchemes: {
                    'http_basic' => {
                      type: 'http',
                      scheme: 'basic'
                    }
                  },
                  links: {
                    'foo' => {
                      operationId: 'foo'
                    }
                  },
                  callbacks: {
                    'onFoo' => {
                      '{$request.query.foo}' => {
                        'get' => {
                          parameters: [],
                          responses: {}
                        }
                      }
                    }
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: [
                  { name: 'Foo' }
                ],
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                'x-foo': 'bar'
              }
            when OpenAPI::V3_1
              {
                openapi: '3.1.2',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                servers: [
                  { url: 'https://foo.bar/foo' }
                ],
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
                    },
                    servers: [
                      { url: 'http:s//foo.baz' }
                    ],
                    parameters: [
                      {
                        name: 'common_parameter',
                        in: 'query',
                        schema: {
                          type: 'string'
                        },
                        required: true
                      }
                    ]
                  }
                },
                components: {
                  schemas: {
                    'response_schema' => {
                      type: %w[object null],
                      properties: {},
                      required: []
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
                            type: %w[string null]
                          }
                        }
                      }
                    }
                  },
                  parameters: {
                    'parameter' => {
                      name: 'parameter',
                      in: 'query',
                      allowEmptyValue: true,
                      schema: {
                        type: %w[string null]
                      }
                    }
                  },
                  examples: {
                    'foo' => {
                      value: 'bar'
                    }
                  },
                  requestBodies: {
                    'request_body' => {
                      content: {
                        'application/json' => {
                          schema: {
                            type: %w[string null]
                          }
                        }
                      },
                      required: false
                    }
                  },
                  headers: {
                    'X-Foo' => {
                      schema: {
                        type: %w[string null]
                      }
                    }
                  },
                  securitySchemes: {
                    'http_basic' => {
                      type: 'http', scheme: 'basic'
                    }
                  },
                  links: {
                    'foo' => {
                      operationId: 'foo'
                    }
                  },
                  callbacks: {
                    'onFoo' => {
                      '{$request.query.foo}' => {
                        'get' => {
                          parameters: [],
                          responses: {}
                        }
                      }
                    }
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: [
                  { name: 'Foo' }
                ],
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                'x-foo': 'bar'
              }
            when OpenAPI::V3_2
              {
                openapi: '3.2.0',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                servers: [
                  { url: 'https://foo.bar/foo' }
                ],
                paths: {
                  '/bar' => {
                    'post' => {
                      operationId: 'operation',
                      parameters: [
                        { '$ref': '#/components/parameters/parameter' }
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
                    },
                    :additionalOperations => {
                      'CUSTOM' => {
                        operationId: 'additional_operation',
                        parameters: [],
                        responses: {}
                      }
                    },
                    servers: [
                      { url: 'http:s//foo.baz' }
                    ],
                    parameters: [
                      {
                        name: 'common_parameter',
                        in: 'query',
                        schema: {
                          type: 'string'
                        },
                        required: true
                      }
                    ]
                  }
                },
                components: {
                  schemas: {
                    'response_schema' => {
                      type: %w[object null],
                      properties: {},
                      required: []
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
                            type: %w[string null]
                          }
                        }
                      }
                    }
                  },
                  parameters: {
                    'parameter' => {
                      name: 'parameter',
                      in: 'query',
                      allowEmptyValue: true,
                      schema: {
                        type: %w[string null]
                      }
                    }
                  },
                  examples: {
                    'foo' => {
                      dataValue: 'bar'
                    }
                  },
                  requestBodies: {
                    'request_body' => {
                      content: {
                        'application/json' => {
                          schema: {
                            type: %w[string null]
                          }
                        }
                      },
                      required: false
                    }
                  },
                  headers: {
                    'X-Foo' => {
                      schema: {
                        type: %w[string null]
                      }
                    }
                  },
                  securitySchemes: {
                    'http_basic' => {
                      type: 'http', scheme: 'basic'
                    }
                  },
                  links: {
                    'foo' => {
                      operationId: 'foo'
                    }
                  },
                  callbacks: {
                    'onFoo' => {
                      '{$request.query.foo}' => {
                        'get' => {
                          parameters: [],
                          responses: {}
                        }
                      }
                    }
                  }
                },
                security: [
                  { 'http_basic' => [] }
                ],
                tags: [
                  { name: 'Foo' }
                ],
                externalDocs: {
                  url: 'https://foo.bar/docs'
                },
                'x-foo': 'bar'
              }
            end,
            definitions,
            version,
            method: :openapi_document
          )
        end
      end

      def test_openapi_document_on_inheritance
        definitions = Definitions.new(
          parent: Definitions.new(
            info: { title: 'Foo', version: '1' },
            operations: {
              'foo' => { path: '/foo' }
            },
            tags: [
              { name: 'Foo' }
            ]
          ),
          operations: {
            'bar' => { path: '/bar' }
          },
          tags: [
            { name: 'Bar' }
          ]
        )
        # OpenAPI 2.0
        assert_openapi_equal(
          {
            swagger: '2.0',
            info: {
              title: 'Foo',
              version: '1'
            },
            paths: {
              '/foo' => {
                'get' => {
                  operationId: 'foo',
                  parameters: [],
                  responses: {}
                }
              },
              '/bar' => {
                'get' => {
                  operationId: 'bar',
                  parameters: [],
                  responses: {}
                }
              }
            },
            tags: [
              { name: 'Bar' },
              { name: 'Foo' }
            ]
          },
          definitions,
          '2.0',
          method: :openapi_document
        )
        # OpenAPI 3.0
        assert_openapi_equal(
          {
            openapi: '3.0.4',
            info: {
              title: 'Foo',
              version: '1'
            },
            paths: {
              '/foo' => {
                'get' => {
                  operationId: 'foo',
                  parameters: [],
                  responses: {}
                }
              },
              '/bar' => {
                'get' => {
                  operationId: 'bar',
                  parameters: [],
                  responses: {}
                }
              }
            },
            tags: [
              { name: 'Bar' },
              { name: 'Foo' }
            ]
          },
          definitions,
          '3.0',
          method: :openapi_document
        )
      end

      def test_openapi_document_takes_the_default_server_object
        definitions = Definitions.new(owner: self.class)

        # OpenAPI 2.0
        assert_equal(
          '/jsapi/meta',
          definitions.openapi_document('2.0')['basePath']
        )
        # OpenAPI 3.0
        assert_equal(
          [{ 'url' => '/jsapi/meta' }],
          definitions.openapi_document('3.0')['servers']
        )
      end

      def test_openapi_document_2_0_takes_the_url_parts_from_the_server_object
        openapi_document = Definitions.new(
          servers: [
            { url: 'https://foo.bar/foo' }
          ]
        ).openapi_document('2.0')

        assert_equal(%w[https], openapi_document['schemes'])
        assert_equal('foo.bar', openapi_document['host'])
        assert_equal('/foo', openapi_document['basePath'])
      end

      def test_openapi_document_skips_responses_not_to_be_documented
        definitions = Definitions.new(
          operations: {
            'operation' => {
              responses: {
                '200' => { ref: 'Success' },
                '500' => { ref: 'Error' }
              }
            }
          },
          responses: {
            'Success' => {
              content_type: 'application/json'
            },
            'Error' => {
              content_type: 'application/problem+json',
              nodoc: true
            }
          }
        )
        each_openapi_version do |version|
          openapi_document = definitions.openapi_document(version)

          if version == OpenAPI::V2_0
            assert_equal(%w[application/json], openapi_document['produces'])
            assert_equal(%w[Success], openapi_document['responses'].keys)
          else
            assert_equal(%w[Success], openapi_document.dig('components', 'responses').keys)
          end
        end
      end

      private

      def assert_path_attribute_caching(name)
        method_name = :"common_#{name}"
        pathname = Pathname.from('foo')

        definitions = Definitions.new(
          parent: parent = Definitions.new(
            paths: { pathname => {} }
          ),
          paths: { pathname => {} }
        )
        # Make cached path attributes accessible
        definitions.define_singleton_method(:__cached_path_attributes__) do
          @cache&.fetch(:path_attributes, nil)
        end

        yield definitions.path(pathname)
        assert(
          definitions.__cached_path_attributes__[pathname].blank?,
          'Expected no path attributes to be cached initially.'
        )

        # Query attribute
        definitions.send(method_name, pathname)
        assert(
          definitions.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached."
        )
        # Modify attribute
        yield definitions.path(pathname)
        assert(
          definitions.__cached_path_attributes__.dig(pathname, name).blank?,
          "Expected cached \"#{name}\" path attribute to be invalidated " \
          'after it has been modified.'
        )
        # Query attribute again
        definitions.send(method_name, pathname)
        assert(
          definitions.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (2)."
        )
        # Modify attribute in parent definitions
        yield parent.path(pathname)
        assert(
          definitions.__cached_path_attributes__[pathname].blank?,
          "Expected cached \"#{name}\" to be invalidated after that " \
          'path attribute has been modified in parent definitions.'
        )
        # Query attribute again
        definitions.send(method_name, pathname)
        assert(
          definitions.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (3)."
        )
        # Include another instance
        definitions.include(
          Definitions.new.tap do |included|
            yield included.add_path(pathname)
          end
        )
        assert(
          definitions.__cached_path_attributes__.blank?,
          'Expected all cached path attributes to be invalidated after ' \
          'another Definitions instance has been included.'
        )
        # Query attribute again
        definitions.send(method_name, pathname)
        assert(
          definitions.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (4)."
        )
      end
    end
  end
end
