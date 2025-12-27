# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class ObjectWrapperTest < Minitest::Test
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
      end
    end
  end
end
