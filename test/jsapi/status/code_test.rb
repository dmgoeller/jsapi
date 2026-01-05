# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Status
    class CodeTest < Minitest::Test
      def test_from
        [200, '200', :ok, 'ok', Code.from(200)].each do |value|
          assert(
            (actual = Code.from(value)).value == 200,
            "Expected #{value.inspect} to be transformed " \
            "to status code 200, is: #{actual.inspect}."
          )
        end
      end

      def test_from_returns_nil_if_value_is_nil
        assert_nil(Code.from(nil))
      end

      def test_from_raises_an_error_on_invalid_value
        [0, '0', 'foo', ''].each do |value|
          assert_raises(ArgumentError) do
            Code.from(value)
          end
        end
      end

      def test_match
        code = Code.from(200)

        assert(
          code.match?(other = Code.from(200)),
          "Expected #{other.inspect} to match #{code.inspect}."
        )
        assert_not(
          code.match?(other = Code.from(201)),
          "Expected #{other.inspect} not to match #{code.inspect}."
        )
        assert_not(
          code.match?(nil),
          "Expected nil not to match #{code.inspect}."
        )
      end

      def test_to_i
        assert_equal(200, Code.from(:ok).to_i)
      end
    end
  end
end
