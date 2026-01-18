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

      def test_value_on_conversion
        assert_equal(1, Integer.new('-1', schema(type: 'integer', conversion: :abs)).value)
      end

      def test_empty_predicate
        assert_not(Integer.new('0', schema(type: 'integer')).empty?)
      end
    end
  end
end
