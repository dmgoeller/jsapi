# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class NumberTest < Minitest::Test
      include TestHelper

      def test_value
        assert_equal(0.0, Number.new('0', schema(type: 'number')).value)
      end

      def test_conversion
        schema = schema(type: 'number')
        schema.conversion = ->(n) { n.round(2) }
        assert_equal(1.55, Number.new('1.554', schema).value)
      end

      def test_empty_predicate
        assert_not(Number.new('0.0', schema(type: 'number')).empty?)
      end

      # Malformed values

      def test_malformed_values
        schema = schema(type: 'number')

        [[], {}, true].each do |malformed_value|
          number = Number.new(malformed_value, schema)
          assert(
            number.value.zero?,
            "Expected #value to return 0.0 on #{malformed_value.inspect}"
          )

          errors = Model::Errors.new
          assert_not(
            number.validate(errors),
            "Expected #validate to return false on #{malformed_value.inspect}"
          )
          assert(
            errors.added?(:base, :invalid),
            "Expected object to be invalid on #{malformed_value.inspect}"
          )
        end
      end
    end
  end
end
