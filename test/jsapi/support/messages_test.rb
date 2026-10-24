# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Support
    class MessagesTest < Minitest::Test
      def test_invalid_value
        assert_equal(
          'foo must not be "bar"',
          Messages.invalid_value(name: 'foo', value: 'bar')
        )
        assert_equal(
          'foo must be "bar", is nil',
          Messages.invalid_value(name: 'foo', value: nil, valid_values: %w[bar])
        )
        assert_equal(
          'foo must be one of "foo" or "bar", is nil',
          Messages.invalid_value(name: 'foo', value: nil, valid_values: %w[foo bar])
        )
      end

      def test_join
        assert_equal(
          'Message.',
          Messages.join('Message')
        )
        assert_equal(
          'Message.',
          Messages.join('Message.')
        )
        assert_equal(
          'Message one. Message two.',
          Messages.join('Message one', 'Message two')
        )
        assert_equal(
          'Message one. Message two.',
          Messages.join('Message one.', 'Message two.')
        )
      end
    end
  end
end
