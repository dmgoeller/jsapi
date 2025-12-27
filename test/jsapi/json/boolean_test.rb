# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class BooleanTest < Minitest::Test
      include TestHelper

      def test_value
        assert(Boolean.new('true', schema).value)
        assert_equal(false, Boolean.new('false', schema).value)
      end

      def test_empty_predicate
        assert(!Boolean.new('true', schema).empty?)
        assert(!Boolean.new('false', schema).empty?)
      end
    end
  end
end
