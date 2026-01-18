# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class RescueHandlerTest < Minitest::Test
      def test_raises_an_error_on_invalid_error_class
        # Not a class
        error = assert_raises(ArgumentError) do
          RescueHandler.new(error_class: 'foo')
        end
        assert_equal("\"foo\" isn't a class", error.message)

        # Not StandardError or a subclass of it
        error = assert_raises(ArgumentError) do
          RescueHandler.new(error_class: Exception)
        end
        assert_equal("Exception isn't a rescuable class", error.message)
      end

      def test_match
        rescue_handler = RescueHandler.new

        assert(rescue_handler.match?(StandardError.new))
        assert(rescue_handler.match?(RuntimeError.new))

        assert_not(rescue_handler.match?(Exception.new))
      end
    end
  end
end
