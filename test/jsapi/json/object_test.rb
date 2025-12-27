# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class ObjectTest < Minitest::Test
      include TestHelper

      def test_initialize
        schema = schema(
          type: 'object',
          properties: {
            'foo' => { type: 'string', write_only: true },
            'bar' => { type: 'string', read_only: true }
          }
        )
        object = Object.new({}, schema, context: :request)
        assert_equal(%w[foo], object.raw_attributes.keys)

        object = Object.new({}, schema, context: :response)
        assert_equal(%w[bar], object.raw_attributes.keys)
      end

      def test_model
        object = Object.new({}, schema(type: 'object'))
        assert_kind_of(Model::Base, object.model)
      end

      def test_empty_predicate
        schema = schema(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        assert_predicate(Object.new({}, schema), :empty?)
        assert(!Object.new({ 'foo' => 'bar' }, schema).empty?)
      end

      # Attributes

      def test_bracket_operator
        schema = schema(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        object = Object.new({ 'foo' => 'bar' }, schema)
        assert_equal('bar', object[:foo])

        object = Object.new({}, schema)
        assert_nil(object[nil])
      end

      def test_attribute_predicate
        object = Object.new(
          {},
          schema(
            type: 'object',
            properties: {
              'foo' => { type: 'string' }
            }
          )
        )
        assert(object.attribute?(:foo))
        assert(!object.attribute?(:bar))
        assert(!object.attribute?(nil))
      end

      def test_attributes
        object = Object.new(
          { 'foo' => 'bar' },
          schema(
            type: 'object',
            properties: {
              'foo' => { type: 'string' }
            }
          )
        )
        assert_equal({ 'foo' => 'bar' }, object.attributes)
      end

      def test_attributes_on_polymorphism
        definitions = Meta::Definitions.new(
          schemas: {
            'Base' => {
              discriminator: {
                property_name: 'type'
              },
              properties: {
                'type' => { type: 'string' }
              }
            },
            'Foo' => {
              all_of: [
                { ref: 'Base' }
              ],
              properties: {
                'foo' => { type: 'string' }
              }
            }
          }
        )
        object = Object.new(
          { 'type' => 'Foo', 'foo' => 'bar' },
          schema(definitions, ref: 'Base')
        )
        assert_equal({ 'type' => 'Foo', 'foo' => 'bar' }, object.attributes)
      end

      def test_additional_attributes
        object = Object.new(
          { 'foo' => 'bar', 'bar' => 'foo' },
          schema(
            type: 'object',
            properties: {
              'foo' => { type: 'string' }
            },
            additional_properties: { type: 'string' }
          )
        )
        assert_equal({ 'bar' => 'foo' }, object.additional_attributes)
      end

      # Schema reference

      def test_property_as_reference
        object = Object.new(
          { 'foo' => 'bar' },
          schema(
            Meta::Definitions.new(
              schemas: {
                'Foo' => { type: 'string' }
              }
            ),
            type: 'object',
            properties: {
              'foo' => { schema: 'Foo' }
            }
          )
        )
        assert_equal('bar', object['foo'])
      end

      # Validation

      def test_validates_self_against_schema
        schema = schema(
          type: 'object',
          existence: true,
          properties: {
            'foo' => { type: 'string' }
          }
        )
        object = Object.new({ 'foo' => 'foo' }, schema)
        errors = Model::Errors.new
        assert(object.validate(errors))
        assert_predicate(errors, :empty?)

        object = Object.new({}, schema)
        errors = Model::Errors.new
        assert(!object.validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      def test_validates_attributes_against_property_schema
        schema = schema(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: true }
          }
        )
        object = Object.new({ 'foo' => 'foo' }, schema)
        errors = Model::Errors.new
        assert(object.validate(errors))
        assert_predicate(errors, :empty?)

        object = Object.new({ 'foo' => '' }, schema)
        errors = Model::Errors.new
        assert(!object.validate(errors))
        assert(errors.added?(:foo, "can't be blank"))
      end

      def test_validates_nested_attributes_against_model
        schema = schema(
          type: 'object',
          properties: {
            'foo' => {
              type: 'object',
              properties: {
                'bar' => { type: 'string', existence: true }
              }
            }
          }
        )
        object = Object.new({ 'foo' => { 'bar' => 'Bar' } }, schema)
        errors = Model::Errors.new
        assert(object.validate(errors))
        assert_predicate(errors, :empty?)

        object = Object.new({ 'foo' => { 'bar' => nil } }, schema)
        errors = Model::Errors.new
        assert(!object.validate(errors))
        assert(errors.added?(:foo, "'bar' can't be blank"))
      end
    end
  end
end
