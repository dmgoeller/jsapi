# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class SchemaTest < Minitest::Test
      # ::new

      def test_new_schema
        schema = Schema.new
        assert_kind_of(Schema::Object, schema)
      end

      def test_new_array_schema
        schema = Schema.new(type: 'array')
        assert_kind_of(Schema::Array, schema)
      end

      def test_new_boolean_schema
        schema = Schema.new(type: 'boolean')
        assert_kind_of(Schema::Base, schema)
      end

      def test_new_integer_schema
        schema = Schema.new(type: 'integer')
        assert_kind_of(Schema::Numeric, schema)
      end

      def test_new_number_schema
        schema = Schema.new(type: 'number')
        assert_kind_of(Schema::Numeric, schema)
      end

      def test_new_object_schema
        schema = Schema.new(type: 'object')
        assert_kind_of(Schema::Object, schema)
      end

      def test_new_reference
        schema = Schema.new(ref: 'foo')
        assert_kind_of(Schema::Reference, schema)
      end

      def test_new_string_schema
        schema = Schema.new(type: 'string')
        assert_kind_of(Schema::String, schema)
      end

      def test_new_raises_exception_on_invalid_type
        error = assert_raises(InvalidArgumentError) do
          Schema.new(type: 'foo')
        end
        assert_equal(
          'type must be one of "array", "boolean", "integer", ' \
          '"number", "object" or "string", is "foo"',
          error.message
        )
      end

      # ::wrap

      %w[boolean integer number string].each do |type|
        define_method(:"test_wrap_#{type}_schema") do
          wrapper = Schema.wrap(Schema.new(type: type), nil)
          assert_kind_of(Schema::Wrapper, wrapper)
        end
      end

      def test_wrap_array_schema
        wrapper = Schema.wrap(Schema.new(type: 'array'), nil)
        assert_kind_of(Schema::Array::Wrapper, wrapper)
      end

      def test_wrap_object_schema
        wrapper = Schema.wrap(Schema.new(type: 'object'), nil)
        assert_kind_of(Schema::Object::Wrapper, wrapper)
      end

      def test_wrap_resolves_references
        wrapper = Schema.wrap(
          Schema.new(ref: 'Foo'),
          definitions = Definitions.new(
            schemas: { 'Foo' => {} }
          )
        )
        assert_equal(definitions.schema('Foo'), wrapper.__getobj__)
      end

      def test_wrap_returns_nil_when_schema_is_nil
        assert_nil(Schema.wrap(nil, nil))
      end

      def test_wrap_prevents_double_wrapping
        wrapper = Schema.wrap(Schema.new(type: 'string'), nil)
        assert(wrapper.eql?(Schema.wrap(wrapper, nil)))
      end
    end
  end
end
