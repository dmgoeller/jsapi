# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseNotFoundTest < Minitest::Test
      def test_message_on_no_responses
        error = ResponseNotFound.new(
          Meta::Operation.new('foo'),
          200
        )
        assert_equal(
          '"foo" has no responses',
          error.message
        )
      end

      def test_message_on_single_response
        error = ResponseNotFound.new(
          Meta::Operation.new(
            'foo',
            responses: {
              200 => {}
            }
          ),
          201
        )
        assert_equal(
          '"foo" has no response for status 201',
          error.message
        )
      end
    end
  end
end
