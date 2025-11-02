# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class DefinitionsTest < Minitest::Test
      include OpenAPITestHelper

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

      def test_include_would_not_raise_an_exception_when_including_parent
        base_definitions = Definitions.new

        definitions = Definitions.new(parent: base_definitions)
        definitions.include(base_definitions)

        assert_equal([definitions, base_definitions], definitions.ancestors)
      end

      # Caching

      def test_invalidates_caches
        definitions = Definitions.new
        child_definitions = Definitions.new(parent: definitions)
        dependent_definitions = Definitions.new(include: definitions)

        counter = 0
        increase_counter = -> { counter += 1 }

        # Expected #invalidate_ancestors to be called when another_instance_is_included
        dependent_definitions.stub(:invalidate_ancestors, increase_counter) do
          child_definitions.stub(:invalidate_ancestors, increase_counter) do
            definitions.include(Definitions.new)
          end
        end
        assert_equal(2, counter)

        counter = 0

        # Expected #invalidate_objects to be called when_an_attribute_is_changed
        dependent_definitions.stub(:invalidate_objects, increase_counter) do
          child_definitions.stub(:invalidate_objects, increase_counter) do
            definitions.add_schema('foo')
          end
        end
        assert_equal(2, counter)
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
        definitions = Definitions.new(
          owner: Struct.new(:name).new('Foo::Bar::FooBarController')
        )
        operation = definitions.add_operation
        assert_equal('foo_bar', operation.name)
        assert_equal('/foo_bar', operation.path)
      end

      # Components

      %i[parameter request_body response schema].each do |name|
        define_method("test_add_and_find_#{name}") do
          definitions = Definitions.new
          schema = definitions.send("add_#{name}", 'foo')

          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
          assert_nil(definitions.send("find_#{name}", nil))
        end

        define_method("test_find_#{name}_on_inheritance") do
          base_definitions = Definitions.new
          schema = base_definitions.send("add_#{name}", 'foo')

          definitions = Definitions.new(parent: base_definitions)
          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
        end

        define_method("test_find_#{name}_on_inclusion") do
          included_definitions = Definitions.new
          schema = included_definitions.send("add_#{name}", 'foo')

          definitions = Definitions.new(include: [included_definitions])
          assert_equal(schema, definitions.send("find_#{name}", 'foo'))
        end
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
            Controller::ParametersInvalid.new(Jsapi::Model::Base.new({}))
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

      def test_minimal_openapi_document
        definitions = Definitions.new

        each_openapi_version do |version|
          assert_openapi_equal(
            case version
            when OpenAPI::V2_0
              { swagger: '2.0' }
            when OpenAPI::V3_0
              { openapi: '3.0.3' }
            when OpenAPI::V3_1
              { openapi: '3.1.1' }
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
              operations: {
                '{$request.query.foo}' => {}
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
                },
                securityDefinitions: {
                  'http_basic' => {
                    type: 'basic'
                  }
                },
                security: [
                  {
                    'http_basic' => []
                  }
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
                openapi: '3.0.3',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                servers: [
                  {
                    url: 'https://foo.bar/foo'
                  }
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
                  {
                    'http_basic' => []
                  }
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
                openapi: '3.1.1',
                info: {
                  title: 'Foo',
                  version: '1'
                },
                servers: [
                  {
                    url: 'https://foo.bar/foo'
                  }
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
                    }
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
                  {
                    'http_basic' => []
                  }
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
                  {
                    url: 'https://foo.bar/foo'
                  }
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
                    :additionalOperations => {
                      'CUSTOM' => {
                        operationId: 'additional_operation',
                        parameters: [],
                        responses: {}
                      }
                    }
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
                  {
                    'http_basic' => []
                  }
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
            openapi: '3.0.3',
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
          definitions.openapi_document('2.0')[:basePath]
        )
        # OpenAPI 3.0
        assert_equal(
          [{ url: '/jsapi/meta' }],
          definitions.openapi_document('3.0')[:servers]
        )
      end

      def test_openapi_document_2_0_takes_the_url_parts_from_the_server_object
        openapi_document = Definitions.new(
          servers: [
            { url: 'https://foo.bar/foo' }
          ]
        ).openapi_document('2.0')

        assert_equal(%w[https], openapi_document[:schemes])
        assert_equal('foo.bar', openapi_document[:host])
        assert_equal('/foo', openapi_document[:basePath])
      end
    end
  end
end
