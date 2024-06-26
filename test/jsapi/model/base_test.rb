# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Model
    class BaseTest < Minitest::Test
      def test_equality_operator
        schema = Meta::Schema.new(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))

        assert(model == Base.new(JSON.wrap({ 'foo' => 'bar' }, schema)))
        assert(model != Base.new(JSON.wrap({ 'foo' => nil }, schema)))
      end

      def test_inspect
        # nil and integer
        schema = Meta::Schema.new(type: 'object')
        schema.add_property('foo', type: 'integer')

        model = Base.new(JSON.wrap({ 'foo' => 0 }, schema))
        assert_equal('#<Jsapi::Model::Base foo: 0>', model.inspect)

        model = Base.new(JSON.wrap({ 'foo' => nil }, schema))
        assert_equal('#<Jsapi::Model::Base foo: nil>', model.inspect)

        # string
        schema = Meta::Schema.new(type: 'object')
        schema.add_property('foo', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => 'bar' }, schema))
        assert_equal('#<Jsapi::Model::Base foo: "bar">', model.inspect)

        # nested object
        schema = Meta::Schema.new(type: 'object')
        property = schema.add_property('foo', type: 'object')
        property.schema.add_property('bar', type: 'string')

        model = Base.new(JSON.wrap({ 'foo' => { 'bar' => 'Foo Bar' } }, schema))
        assert_equal(
          '#<Jsapi::Model::Base foo: #<Jsapi::Model::Base bar: "Foo Bar">>',
          model.inspect
        )
      end

      def test_nested
        schema = Meta::Schema.new(type: 'object')
        schema.add_property('nested', type: 'string')

        nested = JSON.wrap({ 'nested' => 'foo' }, schema)
        model = Base.new(nested)

        assert_equal(nested, model.send(:nested))
        assert_equal('foo', model.public_send(:nested))
      end
    end
  end
end
