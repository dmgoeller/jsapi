# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module JSON
    class ArrayTest < Minitest::Test
      def test_initialize
        schema = Meta::Schema.new(
          type: 'array',
          items: {
            type: 'object',
            properties: {
              'foo' => { type: 'string', write_only: true },
              'bar' => { type: 'string', read_only: true }
            }
          }
        )
        array = Array.new([{}], schema, definitions, context: :request)
        assert_equal(%w[foo], array.value.first.attributes.keys)

        array = Array.new([{}], schema, definitions, context: :response)
        assert_equal(%w[bar], array.value.first.attributes.keys)
      end

      def test_value
        schema = Meta::Schema.new(type: 'array', items: { type: 'string' })
        array = Array.new(%w[foo bar], schema, definitions)
        assert_equal(%w[foo bar], array.value)
      end

      def test_empty_predicate
        schema = Meta::Schema.new(type: 'array', items: { type: 'string' })

        array = Array.new([], schema, definitions)
        assert_predicate(array, :empty?)

        array = Array.new(%w[foo bar], schema, definitions)
        assert(!array.empty?)
      end

      # Serialization

      def test_serializable_value
        schema = Meta::Schema.new(type: 'array', items: { type: 'string' })
        array = Array.new(%w[foo bar], schema, definitions)
        assert_equal(%w[foo bar], array.serializable_value)
      end

      # Validation

      def test_validates_self_against_schema
        schema = Meta::Schema.new(
          type: 'array',
          items: { type: 'string' },
          max_items: 2
        )
        errors = Model::Errors.new
        assert(Array.new(%w[foo bar], schema, definitions).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!Array.new(%w[foo bar foo], schema, definitions).validate(errors))
        assert(errors.added?(:base, 'is invalid'))
      end

      def test_validates_items_against_items_schema
        schema = Meta::Schema.new(
          type: 'array',
          items: { type: 'string', existence: true }
        )
        errors = Model::Errors.new
        assert(Array.new([], schema, definitions).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(Array.new(%w[foo bar], schema, definitions).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!Array.new(['foo', nil], schema, definitions).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      # #inspect

      def test_inspect
        schema = Meta::Schema.new(type: 'array', items: { type: 'string' })
        assert_equal(
          '#<Jsapi::JSON::Array [#<Jsapi::JSON::String "foo">]>',
          Array.new(%w[foo], schema, definitions).inspect
        )
      end

      private

      def definitions
        @definitions ||= Meta::Definitions.new
      end
    end
  end
end
