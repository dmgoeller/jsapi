# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Parameter
      class BaseTest < Minitest::Test
        include TestHelper

        def test_name_and_type
          parameter = Base.new('foo', type: 'string')
          assert_equal('foo', parameter.name)
          assert_equal('string', parameter.type)
        end

        def test_example
          parameter = Base.new('foo', type: 'string', example: 'bar')
          assert_equal('bar', parameter.example.value)
        end

        def test_schema
          parameter = Base.new('foo', schema: 'bar')
          assert_equal('bar', parameter.schema.ref)
        end

        def test_raises_exception_on_blank_parameter_name
          error = assert_raises(ArgumentError) { Base.new('') }
          assert_equal("parameter name can't be blank", error.message)
        end

        # Predicate methods

        def test_required_predicate
          parameter = Base.new('foo', existence: true)
          assert(parameter.required?)

          parameter = Base.new('foo', in: 'path')
          assert(parameter.required?)

          parameter = Base.new('foo', existence: false)
          assert_not(parameter.required?)
        end

        # OpenAPI objects

        def test_minimal_openapi_parameter_object
          definitions = Definitions.new

          # Query parameter
          parameter = Base.new('foo', type: 'string', in: 'query')

          each_openapi_version do |version|
            expected_openapi_parameter_object =
              case version
              when OpenAPI::V2_0
                {
                  name: 'foo',
                  in: 'query',
                  type: 'string',
                  allowEmptyValue: true
                }
              when OpenAPI::V3_0
                {
                  name: 'foo',
                  in: 'query',
                  schema: {
                    type: 'string',
                    nullable: true
                  },
                  allowEmptyValue: true
                }
              else
                {
                  name: 'foo',
                  in: 'query',
                  schema: {
                    type: %w[string null]
                  },
                  allowEmptyValue: true
                }
              end

            assert_openapi_equal(
              expected_openapi_parameter_object,
              parameter,
              version,
              definitions
            )
            assert_openapi_equal(
              [expected_openapi_parameter_object],
              parameter,
              version,
              definitions,
              method: :to_openapi_parameters
            )
          end

          # Path parameter
          parameter = Base.new('foo', type: 'string', in: 'path')

          each_openapi_version do |version|
            expected_openapi_parameter_object =
              case version
              when OpenAPI::V2_0
                {
                  name: 'foo',
                  in: 'path',
                  required: true,
                  type: 'string'
                }
              when OpenAPI::V3_0
                {
                  name: 'foo',
                  in: 'path',
                  required: true,
                  schema: {
                    type: 'string',
                    nullable: true
                  }
                }
              else
                {
                  name: 'foo',
                  in: 'path',
                  required: true,
                  schema: {
                    type: %w[string null]
                  }
                }
              end

            assert_openapi_equal(
              expected_openapi_parameter_object,
              parameter,
              version,
              definitions
            )
            assert_openapi_equal(
              [expected_openapi_parameter_object],
              parameter,
              version,
              definitions,
              method: :to_openapi_parameters
            )
          end
        end

        def test_minimal_openapi_parameter_object_on_object
          definitions = Definitions.new

          parameter = Base.new(
            'foo',
            in: 'query',
            type: 'object',
            properties: {
              'bar' => { type: 'string' }
            }
          )
          each_openapi_version do |version|
            # #to_openapi
            case version
            when OpenAPI::V2_0
              error = assert_raises(RuntimeError) do
                parameter.to_openapi(version, definitions)
              end
              assert_equal(
                "OpenAPI 2.0 doesn't allow object parameters in query",
                error.message
              )
            when OpenAPI::V3_0
              assert_equal(
                {
                  name: 'foo',
                  in: 'query',
                  schema: {
                    type: 'object',
                    nullable: true,
                    properties: {
                      'bar' => { type: 'string', nullable: true }
                    },
                    required: []
                  },
                  allowEmptyValue: true
                },
                parameter.to_openapi(version, definitions)
              )
            else
              assert_openapi_equal(
                {
                  name: 'foo',
                  in: 'query',
                  schema: {
                    type: %w[object null],
                    properties: {
                      'bar' => { type: %w[string null] }
                    },
                    required: []
                  },
                  allowEmptyValue: true
                },
                parameter,
                version,
                definitions
              )
            end

            # #to_openapi_parameters
            assert_openapi_equal(
              [
                case version
                when OpenAPI::V2_0
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    type: 'string',
                    allowEmptyValue: true
                  }
                when OpenAPI::V3_0
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    schema: {
                      type: 'string',
                      nullable: true
                    },
                    allowEmptyValue: true
                  }
                else
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    schema: {
                      type: %w[string null]
                    },
                    allowEmptyValue: true
                  }
                end
              ],
              parameter,
              version,
              definitions,
              method: :to_openapi_parameters
            )
          end
        end

        def test_full_openapi_parameter_object
          definitions = Definitions.new

          parameter = Base.new(
            'foo',
            type: 'string',
            existence: true,
            description: 'Lorem ipsum',
            deprecated: true,
            example: 'bar',
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            expected_openapi_parameter_object =
              if version < OpenAPI::V3_0
                {
                  name: 'foo',
                  in: 'query',
                  description: 'Lorem ipsum',
                  required: true,
                  type: 'string',
                  'x-foo': 'bar'
                }
              else
                {
                  name: 'foo',
                  in: 'query',
                  description: 'Lorem ipsum',
                  required: true,
                  deprecated: true,
                  schema: {
                    type: 'string'
                  },
                  examples: {
                    'default' =>
                      if version < OpenAPI::V3_2
                        { value: 'bar' }
                      else
                        { dataValue: 'bar' }
                      end
                  },
                  'x-foo': 'bar'
                }
              end

            assert_openapi_equal(
              expected_openapi_parameter_object,
              parameter,
              version,
              definitions
            )
            assert_openapi_equal(
              [expected_openapi_parameter_object],
              parameter,
              version,
              definitions,
              method: :to_openapi_parameters
            )
          end
        end

        def test_full_openapi_parameter_object_on_object
          definitions = Definitions.new

          parameter = Base.new(
            'foo',
            type: 'object',
            description: 'lorem ipsum',
            existence: true,
            deprecated: true,
            properties: {
              'bar' => {
                type: 'string',
                existence: true,
                description: 'dolor sit amet',
                deprecated: true,
                openapi_extensions: { 'bar' => 'foo' }
              }
            },
            example: { 'bar' => 'consectetur adipisici elit' },
            openapi_extensions: { 'foo' => 'bar' }
          )
          # #to_openapi
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                name: 'foo',
                in: 'query',
                description: 'lorem ipsum',
                required: true,
                deprecated: true,
                schema: {
                  type: 'object',
                  properties: {
                    'bar' => {
                      type: 'string',
                      description: 'dolor sit amet',
                      deprecated: true,
                      'x-bar': 'foo'
                    }
                  },
                  required: %w[bar]
                },
                examples: {
                  'default' =>
                    if version < OpenAPI::V3_2
                      {
                        value: {
                          'bar' => 'consectetur adipisici elit'
                        }
                      }
                    else
                      {
                        dataValue: {
                          'bar' => 'consectetur adipisici elit'
                        }
                      }
                    end
                },
                'x-foo': 'bar'
              },
              parameter,
              version,
              definitions
            )
          end

          # #to_openapi_parameters
          each_openapi_version do |version|
            assert_openapi_equal(
              [
                if version < OpenAPI::V3_0
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    description: 'dolor sit amet',
                    required: true,
                    type: 'string',
                    'x-foo': 'bar',
                    'x-bar': 'foo'
                  }
                else
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    description: 'dolor sit amet',
                    required: true,
                    deprecated: true,
                    schema: {
                      type: 'string',
                      description: 'dolor sit amet',
                      'x-bar': 'foo'
                    },
                    'x-foo': 'bar'
                  }
                end
              ],
              parameter,
              version,
              definitions,
              method: :to_openapi_parameters
            )
          end
        end

        def test_openapi_parameter_object_on_querystring
          parameter = Base.new('query', type: 'string', in: 'querystring')

          each_openapi_version do |version|
            if version < OpenAPI::V3_2
              assert_openapi_equal(nil, parameter, version, nil)
              assert_openapi_equal(
                [],
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            else
              expected_openapi_parameter_object = {
                name: 'query',
                in: 'querystring',
                content: {
                  'text/plain' => {
                    schema: {
                      type: %w[string null]
                    }
                  }
                }
              }
              assert_openapi_equal(
                expected_openapi_parameter_object,
                parameter,
                version,
                nil
              )
              assert_openapi_equal(
                [expected_openapi_parameter_object],
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            end
          end
        end

        def test_openapi_parameter_object_on_querystring_as_string
          parameter = Base.new(
            'query',
            in: 'querystring',
            type: 'string',
            existence: :allow_empty
          )

          each_openapi_version do |version|
            if version < OpenAPI::V3_2
              assert_openapi_equal(nil, parameter, version, nil)
              assert_openapi_equal(
                [],
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            else
              expected_openapi_parameter_object = {
                name: 'query',
                in: 'querystring',
                required: true,
                content: {
                  'text/plain' => {
                    schema: {
                      type: 'string'
                    }
                  }
                }
              }
              assert_openapi_equal(
                expected_openapi_parameter_object,
                parameter,
                version,
                nil
              )
              assert_openapi_equal(
                [expected_openapi_parameter_object],
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            end
          end
        end

        def test_openapi_parameter_object_on_querystring_as_object
          parameter = Base.new(
            'query',
            in: 'querystring',
            properties: {
              'foo' => {
                type: 'string',
                existence: true
              }
            },
            existence: true
          )
          each_openapi_version do |version|
            if version < OpenAPI::V3_2
              expected_openapi_parameter_objects = [
                if version == OpenAPI::V2_0
                  {
                    name: 'foo',
                    in: 'query',
                    required: true,
                    type: 'string'
                  }
                else
                  {
                    name: 'foo',
                    in: 'query',
                    required: true,
                    schema: { type: 'string' }
                  }
                end
              ]
              assert_openapi_equal(nil, parameter, version, nil)
              assert_openapi_equal(
                expected_openapi_parameter_objects,
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            else
              expected_openapi_parameter_object = {
                name: 'query',
                in: 'querystring',
                required: true,
                content: {
                  'text/plain' => {
                    schema: {
                      type: 'object',
                      properties: {
                        'foo' => {
                          type: 'string'
                        }
                      },
                      required: %w[foo]
                    }
                  }
                }
              }
              assert_openapi_equal(
                expected_openapi_parameter_object,
                parameter,
                version,
                nil
              )
              assert_openapi_equal(
                [expected_openapi_parameter_object],
                parameter,
                version,
                nil,
                method: :to_openapi_parameters
              )
            end
          end
        end

        def test_openapi_parameter_object_with_minimal_content
          parameter = Base.new(
            'foo',
            type: 'string',
            content_type: 'text/plain'
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                name: 'foo',
                in: 'query',
                allowEmptyValue: true,
                content: {
                  'text/plain' => {
                    schema:
                      if version == OpenAPI::V3_0
                        {
                          type: 'string',
                          nullable: true
                        }
                      else
                        {
                          type: %w[string null]
                        }
                      end
                  }
                }
              },
              parameter,
              version,
              nil
            )
          end
        end

        def test_openapi_parameter_object_with_full_content
          parameter = Base.new(
            'foo',
            type: 'string',
            content_type: 'text/plain',
            example: 'bar'
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                name: 'foo',
                in: 'query',
                allowEmptyValue: true,
                content: {
                  'text/plain' => {
                    schema:
                      if version == OpenAPI::V3_0
                        {
                          type: 'string',
                          nullable: true
                        }
                      else
                        {
                          type: %w[string null]
                        }
                      end,
                    examples: {
                      'default' =>
                        if version < OpenAPI::V3_2
                          { value: 'bar' }
                        else
                          { dataValue: 'bar' }
                        end
                    }
                  }
                }
              },
              parameter,
              version,
              nil
            )
          end
        end

        def test_openapi_parameter_object_on_directional_properties
          definitions = Definitions.new(
            schemas: {
              'Foo' => {
                properties: {
                  'inbound' => {
                    type: 'string',
                    write_only: true
                  },
                  'outbound' => {
                    type: 'string',
                    read_only: true
                  }
                }
              }
            }
          )
          parameter = Base.new('foo', schema: 'Foo')

          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_equal(
              %w[foo[inbound]],
              parameter.to_openapi_parameters(version, definitions).map { |p| p[:name] }
            )
          end
        end

        def test_openapi_parameter_name_on_array
          openapi_parameters = Base.new(
            'foo',
            type: 'array',
            items: { type: 'string' }
          ).to_openapi_parameters('2.0', Definitions.new)

          assert_equal('foo[]', openapi_parameters.first[:name])
        end

        def test_openapi_parameter_name_on_nested_array
          openapi_parameters = Base.new(
            'foo',
            type: 'object',
            properties: {
              'bar' => {
                type: 'array',
                items: { type: 'string' }
              }
            }
          ).to_openapi_parameters('2.0', Definitions.new)

          assert_equal('foo[bar][]', openapi_parameters.first[:name])
        end

        def test_openapi_parameter_name_on_nested_object
          openapi_parameters = Base.new(
            'foo',
            type: 'object',
            properties: {
              'bar': {
                type: 'object',
                properties: {
                  'foo_bar' => { type: 'string' }
                }
              }
            }
          ).to_openapi_parameters('2.0', Definitions.new)

          assert_equal('foo[bar][foo_bar]', openapi_parameters.first[:name])
        end
      end
    end
  end
end
