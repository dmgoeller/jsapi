# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module DOM
    class BaseObjectTest < Minitest::Test
      # Predicate methods tests

      def test_empty_predicate
        assert(!BaseObject.new(nil).empty?)
      end

      def test_null_predicate
        assert(!BaseObject.new(nil).null?)
      end

      # Validation tests

      def test_validates_presence
        schema = Meta::Schema.new(type: 'string', existence: true)

        errors = Model::Errors.new
        assert(DOM.wrap('foo', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!DOM.wrap('', schema).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      def test_validates_allow_empty
        schema = Meta::Schema.new(type: 'string', existence: :allow_empty)

        errors = Model::Errors.new
        assert(DOM.wrap('', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!DOM.wrap(nil, schema).validate(errors))
        assert(errors.added?(:base, "can't be blank"))
      end

      def test_validates_self_against_schema
        schema = Meta::Schema.new(type: 'string', pattern: /fo/)

        errors = Model::Errors.new
        assert(DOM.wrap(nil, schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(DOM.wrap('foo', schema).validate(errors))
        assert_predicate(errors, :empty?)

        errors = Model::Errors.new
        assert(!DOM.wrap('bar', schema).validate(errors))
        assert(errors.added?(:base, 'is invalid'))
      end
    end
  end
end
