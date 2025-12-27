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

      def test_value_on_conversion
        schema = schema(type: 'number')
        schema.conversion = ->(n) { n.round(2) }
        assert_equal(1.55, Number.new('1.554', schema).value)
      end

      def test_empty_predicate
        assert(!Number.new('0.0', schema(type: 'number')).empty?)
      end
    end
  end
end
