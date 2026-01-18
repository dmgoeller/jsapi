# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class StringTest < Minitest::Test
      include TestHelper

      def test_value_on_default_format
        string = String.new('foo', schema(type: 'string'))
        assert_equal('foo', string.value)
      end

      def test_value_on_conversion
        schema = schema(type: 'string', conversion: :upcase)
        assert_equal('FOO', String.new('foo', schema).value)
      end

      def test_value_and_validity_on_date_format
        schema = schema(type: 'string', format: 'date')
        errors = Model::Errors.new

        # valid value
        string = String.new('2099-12-31', schema)
        assert_equal(Date.new(2099, 12, 31), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)

        # invalid value
        string = String.new('foo', schema)
        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end

      def test_value_and_validity_on_date_time_format
        schema = schema(type: 'string', format: 'date-time')
        errors = Model::Errors.new

        # valid value
        string = String.new('2099-12-31', schema)
        assert_equal(DateTime.new(2099, 12, 31), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)

        # invalid value
        string = String.new('foo', schema)
        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end

      def test_value_and_validity_on_duration_format
        schema = schema(type: 'string', format: 'duration')
        errors = Model::Errors.new

        # valid value
        string = String.new('P1D', schema)
        assert_equal(ActiveSupport::Duration.build(86_400), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)

        # invalid value
        string = String.new('foo', schema)
        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end

      def test_empty_predicate
        schema = schema(type: 'string')
        assert_predicate(String.new('', schema), :empty?)
        assert_not(String.new('foo', schema).empty?)
      end
    end
  end
end
