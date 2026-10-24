# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    class ExceptionsTest < Minitest::Test
      class ServerError < StandardError; end
      class InternalServerError < ServerError; end

      def test_registering_error_classes
        base_class = Class.new do
          include Exceptions
          raises ServerError, on: '5xx'
        end
        client_class = Class.new(base_class) do
          raises InternalServerError, on: '500'
        end

        assert_nil(base_class.error_class_for(400))
        assert_equal(ServerError, base_class.error_class_for(500))
        assert_equal(ServerError, base_class.error_class_for(501))

        assert_nil(client_class.error_class_for(400))
        assert_equal(InternalServerError, client_class.error_class_for(500))
        assert_equal(ServerError, client_class.error_class_for(501))
      end

      def test_raises_an_error_on_invalid_argument
        # Argument isn't a class
        error = assert_raises(ArgumentError) do
          Class.new do
            include Exceptions
            raises 'foo', on: nil
          end
        end
        assert_equal("\"foo\" isn't a class", error.message)

        # Argument isn't a subclass of StandardError
        error = assert_raises(ArgumentError) do
          Class.new do
            include Exceptions
            raises String, on: nil
          end
        end
        assert_equal("String isn't a subclass of StandardError", error.message)
      end
    end
  end
end
