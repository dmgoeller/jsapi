# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class ArrayTest < Minitest::Test
      include TestHelper

      def test_initialize
        schema = schema(
          type: 'array',
          items: {
            type: 'object',
            properties: {
              'foo' => { type: 'string', write_only: true },
              'bar' => { type: 'string', read_only: true }
            }
          }
        )
        { request: %w[foo], response: %w[bar] }.each do |context, attribute_names|
          assert_equal(
            attribute_names,
            Array.new([{}], schema, context: context).value.first.attributes.keys
          )
        end
      end

      def test_value
        schema = schema(type: 'array', items: { type: 'string' })
        assert_equal(%w[foo bar], Array.new(%w[foo bar], schema).value)
      end

      def test_empty_predicate
        schema = schema(type: 'array', items: { type: 'string' })

        assert_predicate(Array.new([], schema), :empty?)
        assert_not(Array.new(%w[foo bar], schema).empty?)
      end

      # Serialization

      def test_serializable_value
        schema = schema(type: 'array', items: { type: 'string' })
        assert_equal(%w[foo bar], Array.new(%w[foo bar], schema).serializable_value)
      end

      # Validation

      def test_validates_self_against_schema
        schema = schema(
          type: 'array',
          items: { type: 'string' },
          max_items: 2
        )
        errors = Model::Errors.new
        assert(Array.new(%w[foo bar], schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!Array.new(%w[foo bar foo], schema).validate(errors))
        assert(errors.added?(:base, 'is invalid'))
      end

      def test_validates_items_against_items_schema
        schema = schema(
          type: 'array',
          items: { type: 'string', existence: true }
        )
        errors = Model::Errors.new
        assert(Array.new([], schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(Array.new(%w[foo bar], schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!Array.new(['foo', nil], schema).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::JSON::Array [#<Jsapi::JSON::String "foo">]>',
          Array.new(%w[foo], schema(type: 'array', items: { type: 'string' })).inspect
        )
      end
    end
  end
end
