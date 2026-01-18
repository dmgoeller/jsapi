# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class PropertyTest < Minitest::Test
      include TestHelper

      def test_initialize
        property = Property.new('foo', type: 'string')
        assert_equal('foo', property.name)
        assert_equal('string', property.type)
      end

      def test_raises_exception_on_blank_name
        error = assert_raises(ArgumentError) { Property.new('') }
        assert_equal("property name can't be blank", error.message)
      end

      # Readers

      def test_reader
        property = Property.new('foo')
        assert_equal('bar', property.reader.call({ foo: 'bar' }))
      end

      def test_reader_on_camel_case
        property = Property.new('fooBar')
        assert_equal('bar', property.reader.call({ foo_bar: 'bar' }))
      end

      def test_reader_on_alternative_source
        property = Property.new('foo', source: 'bar')
        assert_equal('bar', property.reader.call({ bar: 'bar' }))
      end

      # Predicate methods

      def test_required_predicate
        property = Property.new('foo', existence: true)
        assert(property.required?)

        property = Property.new('foo', existence: false)
        assert_not(property.required?)
      end

      # OpenAPI objects

      def test_openapi_schema_object_on_read_only
        property = Property.new(
          'foo',
          type: 'string',
          existence: true,
          read_only: true
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            {
              type: 'string',
              readOnly: true
            },
            property,
            version
          )
        end
      end

      def test_openapi_schema_object_on_write_only
        property = Property.new(
          'foo',
          type: 'string',
          existence: true,
          write_only: true
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            if version == OpenAPI::V2_0
              { type: 'string' }
            else
              {
                type: 'string',
                writeOnly: true
              }
            end,
            property,
            version
          )
        end
      end
    end
  end
end
