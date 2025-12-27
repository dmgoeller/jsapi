# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class ObjectTest < Minitest::Test
        include TestHelper

        def test_add_property
          schema = Object.new
          property = schema.add_property('foo', type: 'string')
          assert(property.equal?(schema.property('foo')))
        end

        def test_add_property_raises_an_error_when_frozen
          schema = Object.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.add_property('foo')
          end
        end

        # #resolve_properties

        def test_resolve_properties
          definitions = Definitions.new(
            schemas: {
              'Foo' => {
                properties: {
                  'foo' => { write_only: true }
                }
              }
            }
          )
          schema = Object.new(
            all_of: { ref: 'Foo' },
            properties: {
              'bar' => { read_only: true }
            }
          )
          properties = schema.resolve_properties(definitions)
          assert_equal(%w[foo bar], properties.keys)

          properties = schema.resolve_properties(definitions, context: :request)
          assert_equal(%w[foo], properties.keys)

          properties = schema.resolve_properties(definitions, context: :response)
          assert_equal(%w[bar], properties.keys)
        end

        def test_resolve_properties_raises_an_error_on_circular_reference
          definitions = Definitions.new(
            schemas: {
              'Foo' => {
                all_of: { ref: 'Bar' }
              },
              'Bar' => {
                all_of: { ref: 'Foo' }
              }
            }
          )
          schema = Object.new(all_of: { ref: 'Foo' })

          error = assert_raises(RuntimeError) do
            schema.resolve_properties(definitions)
          end
          assert_equal('circular reference: Foo', error.message)
        end

        # JSON Schema objects

        def test_minimal_json_schema_object
          schema = Object.new(existence: true)
          assert_json_equal(
            {
              type: 'object',
              properties: {},
              required: []
            },
            schema.to_json_schema
          )
        end

        def test_full_json_schema_object
          schema = Object.new(
            all_of: [{ ref: 'Foo' }],
            properties: {
              'foo' => {
                type: 'string',
                existence: true
              },
              'bar' => {
                type: 'integer',
                existence: false
              }
            },
            additional_properties: { type: 'string' }
          )
          assert_json_equal(
            {
              type: %w[object null],
              allOf: [
                { '$ref': '#/definitions/Foo' }
              ],
              properties: {
                'foo' => {
                  type: 'string'
                },
                'bar' => {
                  type: %w[integer null]
                }
              },
              additionalProperties: {
                type: %w[string null]
              },
              required: %w[foo]
            },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_minimal_openapi_schema_object
          schema = Object.new(existence: true)

          each_openapi_version do |version|
            assert_openapi_equal(
              {
                type: 'object',
                properties: {},
                required: []
              },
              schema,
              version
            )
          end
        end

        def test_full_openapi_schema_object
          schema = Object.new(
            all_of: [{ ref: 'Foo' }],
            discriminator: { property_name: 'foo' },
            properties: {
              'foo' => {
                type: 'string',
                existence: true
              },
              'bar' => {
                type: 'integer',
                existence: false
              }
            },
            additional_properties: { type: 'string' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  type: 'object',
                  allOf: [
                    { '$ref': '#/definitions/Foo' }
                  ],
                  discriminator: 'foo',
                  properties: {
                    'foo' => {
                      type: 'string'
                    },
                    'bar' => {
                      type: 'integer'
                    }
                  },
                  additionalProperties: {
                    type: 'string'
                  },
                  required: %w[foo]
                }
              when OpenAPI::V3_0
                {
                  type: 'object',
                  nullable: true,
                  allOf: [
                    { '$ref': '#/components/schemas/Foo' }
                  ],
                  discriminator: {
                    propertyName: 'foo'
                  },
                  properties: {
                    'foo' => {
                      type: 'string'
                    },
                    'bar' => {
                      type: 'integer',
                      nullable: true
                    }
                  },
                  additionalProperties: {
                    type: 'string',
                    nullable: true
                  },
                  required: %w[foo]
                }
              else
                {
                  type: %w[object null],
                  allOf: [
                    { '$ref': '#/components/schemas/Foo' }
                  ],
                  discriminator: {
                    propertyName: 'foo'
                  },
                  properties: {
                    'foo' => {
                      type: 'string'
                    },
                    'bar' => {
                      type: %w[integer null]
                    }
                  },
                  additionalProperties: {
                    type: %w[string null]
                  },
                  required: %w[foo]
                }
              end,
              schema,
              version
            )
          end
        end
      end
    end
  end
end
