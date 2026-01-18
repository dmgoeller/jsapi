# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Model
    class NestedErrorTest < Minitest::Test
      def test_equality_operator
        error = NestedError.new(:foo, Error.new(nil, :bar))

        other = NestedError.new(:foo, Error.new(nil, :bar))
        assert(error == other)

        other = NestedError.new(:bar, Error.new(nil, :foo))
        assert(error != other)
      end

      def test_full_message
        error = NestedError.new(:foo, Error.new(nil, :bar))
        assert_equal("'foo.bar' is invalid", error.full_message)

        error = NestedError.new(:foo, Error.new(nil, :base))
        assert_equal("'foo' is invalid", error.full_message)
      end

      def test_message
        error = NestedError.new(:foo, Error.new(nil, :bar))
        assert_equal("'bar' is invalid", error.message)

        error = NestedError.new(:foo, Error.new(nil, :base))
        assert_equal('is invalid', error.message)
      end

      def test_match
        error = NestedError.new(:foo, Error.new(nil, :base))
        assert(error.match?(:foo))
        assert(error.match?(:foo, :invalid))
        assert_not(error.match?(:bar))

        error = NestedError.new(:foo, Error.new(nil, :bar))
        assert(error.match?(:foo))
        assert_not(error.match?(:foo, :invalid))
        assert_not(error.match?(:bar))
      end

      def test_strict_match
        error = NestedError.new(:foo, Error.new(nil, :base))
        assert(error.strict_match?(:foo))
        assert(error.strict_match?(:foo, :invalid))
        assert_not(error.strict_match?(:bar))

        error = NestedError.new(:foo, Error.new(nil, :bar))
        assert_not(error.strict_match?(:foo))
      end
    end
  end
end
