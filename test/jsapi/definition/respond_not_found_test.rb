# frozen_string_literal: true

module Jsapi
  module Definition
    class ResponseNotFoundTest < Minitest::Test
      def test_message_on_multiple_responses
        error = ResponseNotFound.new(
          Operation.new('foo'),
          200
        )
        assert_equal(
          '"foo" has no responses',
          error.message
        )
      end

      def test_message_on_single_response
        error = ResponseNotFound.new(
          Operation.new(
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
