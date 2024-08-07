# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module JSON
    class NumberTest < Minitest::Test
      def test_value
        schema = Meta::Schema.new(type: 'number')
        assert_equal(0.0, Number.new('0', schema).value)
      end

      def test_value_on_conversion
        schema = Meta::Schema.new(type: 'number')
        schema.conversion = ->(n) { n.round(2) }
        assert_equal(1.55, Number.new('1.554', schema).value)
      end

      def test_empty_predicate
        schema = Meta::Schema.new(type: 'number')
        assert(!Number.new('0.0', schema).empty?)
      end
    end
  end
end
