# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class IntegerTest < Minitest::Test
      include TestHelper

      def test_value
        assert_equal(0, Integer.new('0', schema(type: 'integer')).value)
      end

      def test_conversion
        assert_equal(1, Integer.new('-1', schema(type: 'integer', conversion: :abs)).value)
      end

      def test_empty_predicate
        assert_not(Integer.new('0', schema(type: 'integer')).empty?)
      end

      # Malformed values

      def test_malformed_values
        schema = schema(type: 'integer')

        [[], {}, true].each do |malformed_value|
          integer = Integer.new(malformed_value, schema)
          assert(
            integer.value.zero?,
            "Expected #value to return 0 on #{malformed_value.inspect}"
          )

          errors = Model::Errors.new
          assert_not(
            integer.validate(errors),
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
