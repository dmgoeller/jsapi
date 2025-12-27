# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class ValueTest < Minitest::Test
      include TestHelper

      def test_empty_predicate
        assert(!Value.new(nil).empty?)
      end

      def test_null_predicate
        assert(!Value.new(nil).null?)
      end

      # Serialization

      def test_serializable_value
        json = JSON.wrap('2099-12-31', schema(type: 'string', format: 'date'))

        assert_equal(Date.new(2099, 12, 31), json.serializable_value)
        assert_equal('2099-12-31', json.serializable_value(jsonify_values: true))
      end

      # Validation

      def test_validates_presence
        schema = schema(type: 'string', existence: true)

        errors = Model::Errors.new
        assert(JSON.wrap('foo', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!JSON.wrap('', schema).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      def test_validates_allow_empty
        schema = schema(type: 'string', existence: :allow_empty)

        errors = Model::Errors.new
        assert(JSON.wrap('', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!JSON.wrap(nil, schema).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      def test_validates_self_against_schema
        schema = schema(type: 'string', pattern: /fo/)

        errors = Model::Errors.new
        assert(JSON.wrap(nil, schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(JSON.wrap('foo', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!JSON.wrap('bar', schema).validate(errors))
        assert(errors.added?(:base, 'is invalid'))
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::JSON::String "foo">',
          JSON.wrap('foo', schema(type: 'string')).inspect
        )
      end
    end
  end
end
