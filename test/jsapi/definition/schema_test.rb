# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class SchemaTest < Minitest::Test
      module_name = "#{name.deconstantize}::Schema"

      # ::new

      Schema::TYPES.each do |type|
        define_method(:"test_new_#{type}_schema") do
          schema = Schema.new(type: type)

          assert_kind_of(
            "#{module_name}::#{type.camelize}".constantize,
            schema
          )
        end
      end

      def test_new_schema
        schema = Schema.new
        assert_kind_of(Schema::Object, schema)
      end

      def test_new_reference
        schema = Schema.new(ref: 'foo')
        assert_kind_of(Schema::Reference, schema)
      end

      def test_new_raises_an_error_on_invalid_type
        error = assert_raises(ArgumentError) do
          Schema.new(type: 'foo')
        end
        assert_equal(
          'type must be one of "array", "boolean", "integer", ' \
          '"number", "object" or "string", is "foo"',
          error.message
        )
      end

      # ::wrap

      Schema::TYPES.each do |type|
        define_method(:"test_wrap_#{type}_schema") do
          wrapper = Schema.wrap(Schema.new(type: type), nil)

          assert_kind_of(
            "Jsapi::Definition::Schema::#{type.camelize}::Wrapper".constantize,
            wrapper
          )
        end
      end

      def test_wrap_nil
        assert_nil(Schema.wrap(nil, nil))
      end

      def test_wrap_schema_reference
        api = API.new(
          schemas: {
            'base' => {}
          }
        )
        base = api.schema('base')

        wrapper = Schema.wrap(Schema.new(ref: 'base'), api)
        assert_equal(base, wrapper.__getobj__)
        assert_equal(Existence::ALLOW_OMITTED, wrapper.existence)

        wrapper = Schema.wrap(Schema.new(ref: 'base', existence: true), api)
        assert_equal(base, wrapper.__getobj__)
        assert_equal(Existence::PRESENT, wrapper.existence)
      end

      def test_prevention_of_double_wrapping
        wrapper = Schema.wrap(Schema.new(type: 'string'), nil)
        assert(wrapper.equal?(Schema.wrap(wrapper, nil)))
      end
    end
  end
end
