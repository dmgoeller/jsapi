# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class StringTest < Minitest::Test
      include TestHelper

      def test_value
        string = String.new('foo', schema(type: 'string'))
        assert_equal('foo', string.value)
      end

      def test_conversion
        schema = schema(type: 'string', conversion: :upcase)
        assert_equal('FOO', String.new('foo', schema).value)
      end

      def test_empty_predicate
        schema = schema(type: 'string')
        assert_predicate(String.new('', schema), :empty?)
        assert_not(String.new('foo', schema).empty?)
      end

      # Formats

      def test_date_format
        schema = schema(type: 'string', format: 'date')
        string = String.new('2099-12-31', schema)
        errors = Model::Errors.new

        assert_equal(Date.new(2099, 12, 31), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)
      end

      def test_date_time_format
        schema = schema(type: 'string', format: 'date-time')
        string = String.new('2099-12-31', schema)
        errors = Model::Errors.new

        assert_equal(DateTime.new(2099, 12, 31), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)
      end

      def test_duration_format
        schema = schema(type: 'string', format: 'duration')
        string = String.new('P1D', schema)
        errors = Model::Errors.new

        assert_equal(ActiveSupport::Duration.build(86_400), string.value)
        assert(string.validate(errors))
        assert(errors.empty?)
      end

      # Malformed values

      def test_malformed_date
        schema = schema(type: 'string', format: 'date')
        string = String.new('foo', schema)
        errors = Model::Errors.new

        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end

      def test_malformed_date_time
        schema = schema(type: 'string', format: 'date-time')
        string = String.new('foo', schema)
        errors = Model::Errors.new

        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end

      def test_malformed_duration
        schema = schema(type: 'string', format: 'duration')
        string = String.new('foo', schema)
        errors = Model::Errors.new

        assert_equal('foo', string.value)
        assert_not(string.validate(errors))
        assert(errors.added?(:base, :invalid))
      end
    end
  end
end
