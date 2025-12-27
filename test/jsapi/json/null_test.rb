# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module JSON
    class NullTest < Minitest::Test
      include TestHelper

      def test_value
        assert_nil(Null.new(schema).value)
      end

      def test_null_predicate
        assert_predicate(Null.new(schema), :null?)
      end

      def test_empty_predicate
        assert_predicate(Null.new(schema), :empty?)
      end

      # Inspection

      def test_inspect
        assert_equal('#<Jsapi::JSON::Null>', Null.new(schema).inspect)
      end
    end
  end
end
