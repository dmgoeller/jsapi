# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class ObjectWrapperTest < Minitest::Test
        include WrapperTestHelper

        # #additional_properties

        def test_additional_properties
          additional_properties = Object::Wrapper.new(
            object = Object.new(
              additional_properties: {}
            ),
            Definitions.new
          ).additional_properties

          assert_kind_of(AdditionalProperties::Wrapper, additional_properties)
          assert_equal(object.additional_properties, additional_properties.__getobj__)
        end

        # #resolve_properties

        def test_resolve_properties
          properties = Object::Wrapper.new(
            Object.new(
              all_of: { ref: 'Foo' },
              properties: { 'bar' => {} }
            ),
            Definitions.new(
              schemas: {
                'Foo' => {
                  properties: { 'foo' => {} }
                }
              }
            )
          ).resolve_properties

          properties.each_value do |property|
            assert_kind_of(Property::Wrapper, property)
          end
        end

        # #resolve_schema

        def test_resolve_schema
          wrapper = Object::Wrapper.new(
            Object.new(
              discriminator: { property_name: 'foo' },
              properties: {
                'foo' => { type: 'string', default: 'Foo' }
              }
            ),
            definitions = Definitions.new(
              schemas: {
                'Foo' => {},
                'Bar' => {}
              }
            )
          )
          resolved_schema = wrapper.resolve_schema({ foo: 'Foo' })
          assert_kind_of(Schema::Wrapper, resolved_schema)
          assert_equal(definitions.schema('Foo'), resolved_schema.__getobj__)

          resolved_schema = wrapper.resolve_schema({ foo: 'Bar' })
          assert_kind_of(Schema::Wrapper, resolved_schema)
          assert_equal(definitions.schema('Bar'), resolved_schema.__getobj__)

          resolved_schema = wrapper.resolve_schema({ foo: nil })
          assert_kind_of(Schema::Wrapper, resolved_schema)
          assert_equal(definitions.schema('Foo'), resolved_schema.__getobj__)
        end

        def test_resolve_schema_on_default_mapping
          resolved_schema = Object::Wrapper.new(
            Object.new(
              discriminator: {
                default_mapping: 'Bar',
                property_name: 'foo'
              },
              properties: {
                'foo' => { type: 'string' }
              }
            ),
            definitions = Definitions.new(
              schemas: { 'Bar' => {} }
            )
          ).resolve_schema({ foo: nil })

          assert_kind_of(Schema::Wrapper, resolved_schema)
          assert_equal(definitions.schema('Bar'), resolved_schema.__getobj__)
        end

        def test_resolve_schema_raises_an_error_when_discriminating_property_is_missing
          wrapper = Object::Wrapper.new(
            Object.new(
              discriminator: { property_name: 'foo' },
              properties: {
                'bar' => { type: 'string' }
              }
            ),
            Definitions.new
          )
          error = assert_raises(RuntimeError) do
            wrapper.resolve_schema({})
          end
          assert_equal('discriminator property must be "bar", is "foo"', error.message)
        end

        def test_resolve_schema_raises_an_error_when_discriminating_value_is_nil
          wrapper = Object::Wrapper.new(
            Object.new(
              discriminator: { property_name: 'foo' },
              properties: {
                'foo' => { type: 'string' }
              }
            ),
            Definitions.new
          )
          error = assert_raises(RuntimeError) do
            wrapper.resolve_schema({})
          end
          assert_equal("discriminating value can't be nil", error.message)
        end

        def test_resolve_schema_raises_an_error_when_discriminating_value_could_not_be_resolved
          wrapper = Object::Wrapper.new(
            Object.new(
              discriminator: {
                property_name: 'foo'
              },
              properties: {
                'foo' => { type: 'string' }
              }
            ),
            Definitions.new
          )
          error = assert_raises(RuntimeError) do
            wrapper.resolve_schema({ foo: 'Foo' })
          end
          assert_equal("inheriting schema couldn't be found: \"Foo\"", error.message)
        end

        def test_resolve_schema_raises_an_error_when_default_mapping_could_not_be_resolved
          wrapper = Object::Wrapper.new(
            Object.new(
              discriminator: {
                default_mapping: 'Bar',
                property_name: 'foo'
              },
              properties: {
                'foo' => { type: 'string' }
              }
            ),
            Definitions.new
          )
          error = assert_raises(RuntimeError) do
            wrapper.resolve_schema({ foo: 'Foo' })
          end
          assert_equal("inheriting schema couldn't be found: \"Foo\" or \"Bar\"", error.message)
        end

        # #jsonify

        def test_jsonify
          wrapper = wrap_schema(
            properties: {
              'foo' => { type: 'string' }
            }
          )
          [{ foo: 'bar' }, { foo: nil }, nil].each do |value|
            assert_json_equal(value&.stringify_keys, wrapper, value)
          end

          assert_json_equal({ 'foo' => nil }, wrapper, {})
        end

        def test_jsonify_on_schema_with_non_nullable_property
          wrapper = wrap_schema(
            properties: {
              'foo' => { type: 'string', existence: :allow_empty }
            }
          )
          [{ foo: 'bar' }, nil].each do |value|
            assert_json_equal(value&.stringify_keys, wrapper, value)
          end

          [{ foo: nil }, {}].each do |value|
            error = assert_raises(JsonifyError) { wrapper.jsonify(value) }
            assert_equal("foo can't be nil", error.message)
          end
        end

        def test_jsonify_on_schema_with_additional_properties
          struct = Struct.new(
            :foo,
            :additional_properties,
            keyword_init: true
          )
          wrapper = wrap_schema(
            properties: {
              'foo' => { type: 'integer' }
            },
            additional_properties: { type: 'string' }
          )

          # Objects with additional properties
          [
            struct.new(foo: 1, additional_properties: { bar: 2 }),
            { foo: 1, bar: 2 },
            { 'foo' => 1, 'bar' => 2 },
            { foo: 1, additional_properties: { foo: 2, bar: 2 } },
            { 'foo' => 1, 'additional_properties' => { 'foo' => 2, 'bar' => 2 } }
          ].each do |value|
            assert_json_equal({ 'foo' => 1, 'bar' => '2' }, wrapper, value)
          end

          # Objects without additional properties
          [struct.new(foo: 1), { foo: 1 }, { 'foo' => 1 }].each do |value|
            assert_json_equal({ 'foo' => 1 }, wrapper, value)
          end
        end

        def test_jsonify_on_schema_with_additional_properties_only
          wrapper = wrap_schema(
            additional_properties: { type: 'string' }
          )
          [{ foo: 'bar' }, { foo: nil }, nil].each do |value|
            assert_json_equal(value&.stringify_keys, wrapper, value)
          end

          assert_json_equal(nil, wrapper, {})
        end

        def test_jsonify_on_schema_with_non_nullable_additional_properties
          wrapper = wrap_schema(
            additional_properties: { type: 'string', existence: :allow_empty }
          )
          [{ foo: 'bar' }, nil].each do |value|
            assert_json_equal(value&.stringify_keys, wrapper, value)
          end

          error = assert_raises(JsonifyError) { wrapper.jsonify({ foo: nil }) }
          assert_equal("foo can't be nil", error.message)
        end

        def test_jsonify_on_schema_with_nested_object
          wrapper = wrap_schema(
            properties: {
              'foo' => {
                type: 'object',
                properties: {
                  'bar' => { type: 'string', existence: true }
                }
              }
            }
          )
          value = { foo: { bar: 'baz' } }
          assert_json_equal(value.deep_stringify_keys, wrapper, value)

          error = assert_raises(JsonifyError) { wrapper.jsonify({ foo: { bar: nil } }) }
          assert_equal("foo.bar can't be nil", error.message)
        end

        def test_jsonify_on_schema_with_polymorphism
          wrapper = Schema.wrap(
            Reference.new(ref: 'base'),
            Definitions.new(
              schemas: {
                'base' => {
                  properties: {
                    'type' => { type: 'string', default: 'foo' }
                  },
                  discriminator: { property_name: 'type' }
                },
                **%w[foo bar].to_h do |name|
                    [
                      name,
                      {
                        all_of: { ref: 'base' },
                        properties: {
                          name => { type: 'string' }
                        }
                      }
                    ]
                end
              }
            )
          )
          [{ type: 'foo', foo: 'bar' }, { foo: 'bar' }].each do |value|
            assert_json_equal({ 'type' => 'foo', 'foo' => 'bar' }, wrapper, value)
          end

          value = { type: 'foo', foo: 'bar' }
          assert_json_equal(value.stringify_keys, wrapper, value)
        end

        def test_jsonify_on_omit
          wrapper = wrap_schema(
            properties: {
              'foo' => { type: 'string' }
            }
          )
          # :empty
          assert_json_equal({ 'foo' => 'bar' }, wrapper, { foo: 'bar' }, omit: :empty)

          [{ foo: '' }, { foo: nil }, {}].each do |value|
            assert_json_equal(nil, wrapper, value, omit: :empty)
          end

          # :nil
          [{ foo: 'bar' }, { foo: '' }].each do |value|
            assert_json_equal(value.stringify_keys, wrapper, value, omit: :nil)
          end

          [{ foo: nil }, {}].each do |value|
            assert_json_equal(nil, wrapper, value, omit: :nil)
          end
        end
      end
    end
  end
end
