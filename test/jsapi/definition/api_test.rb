# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Definition
    class APITest < Minitest::Test
      include TestHelper

      # Inheritance and inclusion

      def test_ancestors
        base1 = API.new
        base2 = API.new(parent: base1)

        included1 = API.new
        included2 = API.new(parent: included1)

        api = API.new(parent: base2, include: [included2, included1])

        assert_equal([base1], base1.ancestors)
        assert_equal([base2, base1], base2.ancestors)
        assert_equal([api, included2, included1, base2, base1], api.ancestors)
      end

      def test_inheritance
        api = API.new(
          parent: parent = API.new(
            schemas: {
              foo: {},
              bar: {}
            }
          ),
          schemas: {
            foo: {}
          }
        )
        foo = api.find_schema('foo')
        assert_predicate(foo, :present?)
        assert_not(foo.equal?(parent.find_schema('foo')))

        bar = api.find_schema('bar')
        assert_predicate(bar, :present?)
        assert(bar.equal?(parent.find_schema('bar')))
      end

      def test_include_raises_an_error_on_circular_dependency
        apis = (1..3).map { |i| API.new(owner: i) }

        apis.second.include(apis.first)
        apis.third.include(apis.second)

        error = assert_raises(ArgumentError) do
          apis.first.include(apis.third)
        end
        assert_equal('detected circular dependency between 1 and 3', error.message)
      end

      def test_include_does_not_raise_an_exception_when_including_parent
        base_api = API.new

        api = API.new(parent: base_api)
        api.include(base_api)

        assert_equal([api, base_api], api.ancestors)
      end

      # Operations

      def test_add_operation
        api = API.new
        operation = api.add_operation('foo')
        assert(operation.equal?(api.operation('foo')))
      end

      def test_add_operation_with_parent_path
        api = API.new
        operation = api.add_operation('foo', 'bar')
        assert_equal(Pathname.new('/bar'), operation.parent_path)
      end

      def test_add_operation_raises_an_error_when_frozen
        api = API.new
        api.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          api.add_operation('foo')
        end
      end

      def test_default_operation_name
        api = API.new(
          owner: Struct.new(:name).new('Foo::Bar::FooBarController')
        )
        operation = api.add_operation nil
        assert_equal('foo_bar', operation.name)
      end

      def test_default_parent_path
        api = API.new(
          owner: Struct.new(:name).new('Foo::Bar::FooBarController')
        )
        operation = api.add_operation nil
        assert_equal(Pathname.new('/foo_bar'), operation.parent_path)

        operation = api.add_operation nil, path: 'foo'
        assert_equal(Pathname.new, operation.parent_path)
      end

      def test_find_operation
        api = API.new
        assert_nil(api.find_operation)

        api.add_operation('foo')

        [nil, 'foo'].each do |operation_name|
          operation = api.find_operation(operation_name)
          assert_kind_of(Operation::Wrapper, operation)
          assert_equal('foo', operation.name)
        end
      end

      def test_find_operation!
        api = API.new
        assert_raises(OperationNotFound) { api.find_operation! }

        api.add_operation('foo')

        [nil, 'foo'].each do |operation_name|
          operation = api.find_operation!(operation_name)
          assert_kind_of(Operation::Wrapper, operation)
          assert_equal('foo', operation.name)
        end
      end

      def test_operation_caching
        api = API.new(operations: { 'foo' => {} })

        # Make cached operations accessible
        api.define_singleton_method(:__cached_operations__) do
          @cache&.fetch(:operations, nil)
        end

        assert(
          api.__cached_operations__.blank?,
          'Expected no operations to be cached initially.'
        )
        # Look up operation
        operation = api.find_operation('foo')
        assert(
          api.__cached_operations__['foo'].present?,
          'Expected operation to be cached.'
        )
        assert(
          operation.equal?(api.find_operation('foo')),
          'Expected cached operation to be returned.'
        )
        # Add another operation
        api.add_operation('bar')
        assert(
          api.__cached_operations__.blank?,
          'Expected cached operations to be invalidated.'
        )
        # Look up operation again
        operation = api.find_operation('foo')
        assert(
          api.__cached_operations__['foo'].present?,
          'Expected operation to be cached again.'
        )
        assert(
          operation.equal?(api.find_operation('foo')),
          'Expected cached operation to be returned.'
        )
      end

      # Paths

      def test_add_path
        api = API.new
        path = api.add_path('foo')

        assert(path.equal?(api.path('foo')))
        assert_equal(Pathname.new('foo'), path.name)
      end

      def test_add_path_raises_an_error_when_frozen
        api = API.new
        api.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          api.add_path('foo')
        end
      end

      %i[description summary].each do |name|
        method_name = :"common_#{name}"

        define_method("test_#{method_name}") do
          api = API.new(
            paths: {
              '/foo' => {
                name => 'Lorem ipsum'
              }
            }
          )
          assert_equal('Lorem ipsum', api.send(method_name, '/foo'))
          assert_nil(api.send(method_name, '/bar'))
          assert_nil(api.send(method_name, nil))
        end

        define_method("test_#{method_name}_on_inheritance") do
          api = API.new(
            parent: API.new(
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
          assert_equal('Lorem ipsum', api.send(method_name, '/foo'))
        end
      end

      def test_common_model
        api = API.new(
          paths: {
            '/foo' => { model: model = Class.new },
            'foo/bar' => {}
          }
        )
        assert_equal(model, api.common_model('/foo/bar'))
        assert_equal(model, api.common_model('/foo'))
        assert_nil(api.common_model('/bar'))
        assert_nil(api.common_model(nil))
      end

      def test_common_model_on_inheritance
        api = API.new(
          parent: API.new(
            paths: {
              '/foo' => { model: model = Class.new }
            }
          ),
          paths: {
            'foo/bar' => {}
          }
        )
        assert_equal(model, api.common_model('/foo/bar'))
        assert_equal(model, api.common_model('/foo'))
        assert_nil(api.common_model('/bar'))
        assert_nil(api.common_model(nil))
      end

      def test_common_model_caching
        assert_path_attribute_caching(:model) do |path|
          path.model = Class.new
        end
      end

      def test_common_parameters
        api = API.new(
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
        assert_equal(%w[foo bar], api.common_parameters('/foo/bar').keys)
        assert_equal(%w[foo], api.common_parameters('/foo').keys)
        assert_nil(api.common_parameters('/bar'))
        assert_nil(api.common_parameters(nil))
      end

      def test_common_parameters_on_inheritance
        api = API.new(
          parent: API.new(
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
        assert_equal(%w[foo bar], api.common_parameters('/foo/bar').keys)
        assert_equal(%w[foo], api.common_parameters('/foo').keys)
      end

      def test_common_parameters_caching
        assert_path_attribute_caching(:parameters) do |path|
          path.add_parameter 'foo', type: 'string'
        end
      end

      def test_common_request_body
        api = API.new(
          paths: {
            '/foo' => {
              request_body: {}
            },
            '/foo/bar' => {}
          }
        )
        request_body = api.common_request_body('/foo')
        assert_predicate request_body, :present?
        assert_equal(request_body, api.common_request_body('/foo/bar'))

        assert_nil(api.common_request_body('/bar'))
        assert_nil(api.common_request_body(nil))
      end

      def test_common_request_body_on_inheritance
        api = API.new(
          parent: API.new(
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
        request_body = api.common_request_body('/foo')
        assert_predicate request_body, :present?

        assert_equal(request_body, api.common_request_body('/foo/bar'))
      end

      def test_common_request_body_caching
        assert_path_attribute_caching(:request_body) do |path|
          path.request_body = { type: 'string' }
        end
      end

      def test_common_responses
        api = API.new(
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
          api.common_responses('/foo/bar').keys
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR],
          api.common_responses('/foo').keys
        )
        assert_nil(api.common_responses('/bar'))
        assert_nil(api.common_responses(nil))
      end

      def test_common_responses_on_inheritance
        api = API.new(
          parent: API.new(
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
          api.common_responses('/foo/bar').keys
        )
        assert_equal(
          [Status::Range::CLIENT_ERROR],
          api.common_responses('/foo').keys
        )
      end

      def test_common_responses_caching
        assert_path_attribute_caching(:responses) do |path|
          path.add_response nil, type: 'string'
        end
      end

      def test_common_security_requirements
        api = API.new(
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
            api.common_security_requirements(pathname).flat_map { |s| s.schemes.keys }
          )
        end
        assert_nil(api.common_security_requirements('/bar'))
        assert_nil(api.common_security_requirements(nil))
      end

      def test_common_security_requirements_on_inheritance
        api = API.new(
          parent: API.new(
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
            api.common_security_requirements(pathname).flat_map { |s| s.schemes.keys }
          )
        end
      end

      def test_common_security_requirements_caching
        assert_path_attribute_caching(:security_requirements) do |path|
          path.add_security_requirement(schemes: {})
        end
      end

      def test_common_servers
        api = API.new(
          paths: {
            '/foo' => {
              servers: [
                { url: 'https://foo.bar/foo' }
              ]
            }
          }
        )
        assert_equal(%w[https://foo.bar/foo], api.common_servers('/foo').map(&:url))
        assert_nil(api.common_servers('bar'))
        assert_nil(api.common_servers(nil))
      end

      def test_common_servers_on_inheritance
        api = API.new(
          parent: API.new(
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
        assert_equal(%w[https://foo.bar/foo], api.common_servers('/foo').map(&:url))
      end

      def test_common_servers_caching
        assert_path_attribute_caching(:servers) do |path|
          path.add_server(url: 'https://foo.bar/foo')
        end
      end

      def test_common_tags
        api = API.new(
          paths: {
            '/foo' => { tags: %w[Foo] },
            '/foo/bar' => { tags: %w[Bar] }
          }
        )
        assert_equal(%w[Foo], api.common_tags('/foo'))
        assert_equal(%w[Bar Foo], api.common_tags('/foo/bar'))
        assert_nil(api.common_tags('/bar'))
        assert_nil(api.common_tags(nil))
      end

      def test_common_tags_on_inheritance
        api = API.new(
          parent: API.new(
            paths: {
              '/foo' => { tags: %w[Foo] }
            }
          ),
          paths: {
            '/foo/bar' => { tags: %w[Bar] }
          }
        )
        assert_equal(%w[Foo], api.common_tags('/foo'))
        assert_equal(%w[Bar Foo], api.common_tags('/foo/bar'))
      end

      def test_common_tags_caching
        assert_path_attribute_caching(:tags) do |path|
          path.add_tag('Foo')
        end
      end

      # Components

      %i[example parameter request_body response schema].each do |name|
        plural_name = name.to_s.pluralize.to_sym

        define_method("test_add_and_find_#{name}") do
          api = API.new
          schema = api.send(:"add_#{name}", 'foo')

          assert_equal(schema, api.send("find_#{name}", 'foo'))
          assert_nil(api.send(:"find_#{name}", nil))
        end

        define_method("test_add_#{name}_raises_an_error_when_frozen") do
          api = API.new
          api.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            api.send(:"add_#{name}", 'foo')
          end
        end

        define_method("test_find_#{name}_on_inheritance") do
          base_api = API.new
          schema = base_api.send(:"add_#{name}", 'foo')

          api = API.new(parent: base_api)
          assert_equal(schema, api.send("find_#{name}", 'foo'))
        end

        define_method("test_find_#{name}_on_inclusion") do
          included_api = API.new
          schema = included_api.send(:"add_#{name}", 'foo')

          api = API.new(include: [included_api])
          assert_equal(schema, api.send("find_#{name}", 'foo'))
        end

        define_method("test_#{name}_caching") do
          api = API.new(
            parent: parent = API.new({ plural_name => {} }),
            plural_name => { 'foo' => {} }
          )
          # Make cached attributes accessible
          api.define_singleton_method(:__cached_attributes__) do
            @cache&.fetch(:attributes, nil)
          end

          assert(
            api.__cached_attributes__.blank?,
            'Expected no attributes to be cached initially.'
          )
          # Query attribute
          api.send(:"find_#{name}", 'foo')
          assert(
            api.__cached_attributes__[plural_name].keys == %w[foo],
            "Expected \"#{name}\" attribute to be cached."
          )
          # Modify attribute
          api.send(:"add_#{name}", 'bar')
          assert(
            api.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after an ' \
            'attribute has been modified.'
          )
          # Query attribute again
          api.send(:"find_#{name}", 'foo')
          assert(
            api.__cached_attributes__[plural_name].keys.sort == %w[bar foo],
            "Expected \"#{name}\" attribute to be cached (2)."
          )
          # Modify attribute in parent API
          parent.send(:"add_#{name}", 'bar')
          assert(
            api.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after an ' \
            'attribute of parent has been modified.'
          )
          # Query attribute again
          api.send(:"find_#{name}", 'foo')
          assert(
            api.__cached_attributes__[plural_name].keys.sort == %w[bar foo],
            "Expected \"#{name}\" attribute to be cached (3)."
          )
          # Include another instance
          api.include(
            API.new(
              plural_name => {
                'baz' => {}
              }
            )
          )
          assert(
            api.__cached_attributes__.blank?,
            'Expected cached attributes to be invalidated after another ' \
            'API instance has been included.'
          )
          # Query attribute again
          api.send(:"find_#{name}", 'foo')
          assert(
            api.__cached_attributes__[plural_name].keys.sort == %w[bar baz foo],
            "Expected \"#{name}\" attribute to be cached (4)."
          )
        end
      end

      # Security requirements

      def test_default_security_requirements
        security_requirements = API.new(
          parent: API.new(
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

        api = API.new(
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
          api.rescue_handler_for(bad_request.new).status_code
        )
        assert_equal(
          Status::Code.from(500),
          api.rescue_handler_for(StandardError.new).status_code
        )
        assert_nil(api.rescue_handler_for(Exception.new))
      end

      # Default values

      def test_default_value
        api = API.new(
          defaults: {
            'array' => { within_requests: [] }
          }
        )
        assert_equal([], api.default_value('array', context: :request))
      end

      def test_default_value_returns_nil_by_default
        api = API.new
        assert_nil(api.default_value(nil))
        assert_nil(api.default_value('array'))
      end

      # Servers

      def test_server
        api = API.new(
          servers: [
            { name: 'production', url: 'https://foo.bar' },
            { name: 'staging', url: 'https://stg.foo.bar' }
          ]
        )
        assert_equal('https://foo.bar', api.server('production').url)
        assert_equal('https://stg.foo.bar', api.server('staging').url)
        assert_nil(api.server('development'))
        assert_nil(api.server(nil))
      end

      # JSON Schema documents

      def test_json_schema_document
        api = API.new(
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
          api.json_schema_document('Foo')
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
          api.json_schema_document('Bar')
        )

        # Others
        assert_json_equal(nil, api.json_schema_document('FooBar'))
      end

      def test_json_schema_document_without_definitions
        api = API.new(
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
          api.json_schema_document('Foo')
        )
      end

      # OpenAPI documents

      def test_minimal_openapi_document
        api = API.new

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
              { openapi: '3.2.1' }
            end,
            api,
            version,
            method: :openapi_document
          )
        end
      end

      def test_full_openapi_document
        api = API.new(
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
                      requestBody: {
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
                      requestBody: {
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
                openapi: '3.2.1',
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
                      requestBody: {
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
            api,
            version,
            method: :openapi_document
          )
        end
      end

      def test_openapi_document_on_inheritance
        api = API.new(
          parent: API.new(
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
          api,
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
          api,
          '3.0',
          method: :openapi_document
        )
      end

      def test_openapi_document_takes_the_default_server_object
        api = API.new(owner: self.class)

        # OpenAPI 2.0
        assert_equal(
          '/jsapi/definition',
          api.openapi_document('2.0')['basePath']
        )
        # OpenAPI 3.0
        assert_equal(
          [{ 'url' => '/jsapi/definition' }],
          api.openapi_document('3.0')['servers']
        )
      end

      def test_openapi_document_2_0_takes_the_url_parts_from_the_server_object
        openapi_document = API.new(
          servers: [
            { url: 'https://foo.bar/foo' }
          ]
        ).openapi_document('2.0')

        assert_equal(%w[https], openapi_document['schemes'])
        assert_equal('foo.bar', openapi_document['host'])
        assert_equal('/foo', openapi_document['basePath'])
      end

      def test_openapi_document_skips_responses_not_to_be_documented
        api = API.new(
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
              content_type: 'application/json',
              type: 'object'
            },
            'Error' => {
              content_type: 'application/problem+json',
              type: 'object',
              nodoc: true
            }
          }
        )
        each_openapi_version do |version|
          openapi_document = api.openapi_document(version)

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

        api = API.new(
          parent: parent = API.new(
            paths: { pathname => {} }
          ),
          paths: { pathname => {} }
        )
        # Make cached path attributes accessible
        api.define_singleton_method(:__cached_path_attributes__) do
          @cache&.fetch(:path_attributes, nil)
        end

        yield api.path(pathname)
        assert(
          api.__cached_path_attributes__[pathname].blank?,
          'Expected no path attributes to be cached initially.'
        )

        # Query attribute
        api.send(method_name, pathname)
        assert(
          api.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached."
        )
        # Modify attribute
        yield api.path(pathname)
        assert(
          api.__cached_path_attributes__.dig(pathname, name).blank?,
          "Expected cached \"#{name}\" path attribute to be invalidated " \
          'after it has been modified.'
        )
        # Query attribute again
        api.send(method_name, pathname)
        assert(
          api.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (2)."
        )
        # Modify attribute in parent API
        yield parent.path(pathname)
        assert(
          api.__cached_path_attributes__[pathname].blank?,
          "Expected cached \"#{name}\" to be invalidated after that " \
          'path attribute has been modified in parent.'
        )
        # Query attribute again
        api.send(method_name, pathname)
        assert(
          api.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (3)."
        )
        # Include another instance
        api.include(
          API.new.tap do |included|
            yield included.add_path(pathname)
          end
        )
        assert(
          api.__cached_path_attributes__.blank?,
          'Expected all cached path attributes to be invalidated after ' \
          'another API instance has been included.'
        )
        # Query attribute again
        api.send(method_name, pathname)
        assert(
          api.__cached_path_attributes__.dig(pathname, name).present?,
          "Expected \"#{name}\" path attribute to be cached (4)."
        )
      end
    end
  end
end
