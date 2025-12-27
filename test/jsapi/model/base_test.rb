# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Model
    class BaseTest < Minitest::Test
      # ::model_name

      def test_model_name
        model_name = Base.model_name
        assert_equal(Base, model_name.klass)
        assert_nil(model_name.namespace)
      end

      def test_model_name_on_anonymous_class
        model_name = Class.new(Base).model_name
        assert_equal(Base, model_name.klass)
        assert_nil(model_name.namespace)
      end

      # Equality operator

      def test_equality_operator
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))

        assert(model == Base.new(JSON.wrap({ 'foo' => 'bar' }, schema)))
        assert(model != Base.new(JSON.wrap({ 'foo' => nil }, schema)))
      end

      # Attributes

      def test_bracket_operator
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal('bar', model['foo'])
        assert_equal('bar', model[:foo])
      end

      def test_attribute_predicate
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({}, schema))

        assert(model.attribute?('foo'))
        assert(model.attribute?(:foo))

        assert(!model.attribute?('bar'))
        assert(!model.attribute?(:bar))
      end

      def test_attributes
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({}, schema))
        assert_equal({ 'foo' => nil }, model.attributes)

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal({ 'foo' => 'bar' }, model.attributes)

        model.additional_attributes
      end

      def test_additional_attributes
        schema = schema(
          type: 'object',
          additional_properties: { type: 'string' }
        )
        model = Base.new(JSON.wrap({}, schema))
        assert_equal({}, model.additional_attributes)

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal({ 'foo' => 'bar' }, model.additional_attributes)
      end

      def test_attribute_reader
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal('bar', model.foo)
      end

      def test_attribute_reader_on_camel_case
        schema = schema(type: 'object')
        schema.add_property('fooBar', type: 'string')

        model = Base.new(JSON.wrap({ 'fooBar' => 'bar' }, schema))
        assert_equal('bar', model.foo_bar)
      end

      def test_respond_to
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({}, schema))

        assert(model.respond_to?(:foo))
        assert(!model.respond_to?(:bar))
      end

      def test_raises_an_error_on_missing_attribute
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({}, schema))
        assert_raises(NoMethodError) { model.bar }
      end

      # Validation

      def test_validates_self_against_schema
        schema = schema(type: 'object', existence: true)
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_predicate(model, :valid?)

        model = Base.new(JSON.wrap({}, schema))
        assert_predicate(model, :invalid?)
        assert_equal(["can't be blank"], model.errors.full_messages)
      end

      def test_validates_attributes_against_property_schemas
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string', existence: true)

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_predicate(model, :valid?)

        model = Base.new(JSON.wrap({ 'foo' => '' }, schema))
        assert_predicate(model, :invalid?)
        assert(model.errors.added?(:foo, "can't be blank"))
      end

      def test_validates_nested_attributes_against_nested_property_schemas
        schema = schema(type: 'object')
        property = schema.add_property('foo', type: 'object')
        property.schema.add_property('bar', type: 'string', existence: true)

        model = Base.new(JSON.wrap({ 'foo' => { 'bar' => 'Foo bar' } }, schema))
        assert_predicate(model, :valid?)

        model = Base.new(JSON.wrap({ 'foo' => {} }, schema))
        assert_predicate(model, :invalid?)
        assert(model.errors.added?(:foo, "'bar' can't be blank"))
      end

      # Inspection

      def test_inspect
        model = Base.new(JSON.wrap({}, schema(type: 'object')))
        assert_equal('#<Jsapi::Model::Base>', model.inspect)

        # nil and integer
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'integer')

        model = Base.new(JSON.wrap({ 'foo' => 0 }, schema))
        assert_equal('#<Jsapi::Model::Base foo: 0>', model.inspect)

        model = Base.new(JSON.wrap({ 'foo' => nil }, schema))
        assert_equal('#<Jsapi::Model::Base foo: nil>', model.inspect)

        # string
        schema = schema(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal('#<Jsapi::Model::Base foo: "bar">', model.inspect)

        # nested object
        schema = schema(type: 'object')
        property = schema.add_property('foo', type: 'object')
        property.schema.add_property('bar', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => { 'bar' => 'Foo Bar' } }, schema))
        assert_equal(
          '#<Jsapi::Model::Base foo: #<Jsapi::Model::Base bar: "Foo Bar">>',
          model.inspect
        )
      end

      private

      def schema(**keywords)
        Meta::Schema.wrap(Meta::Schema.new(**keywords), Meta::Definitions.new)
      end
    end
  end
end
