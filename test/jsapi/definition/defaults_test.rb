# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class DefaultsTest < Minitest::Test
      def test_value
        defaults = Defaults.new(within_requests: 'foo', within_responses: 'bar')

        assert_equal('foo', defaults.value(context: :request))
        assert_equal('bar', defaults.value(context: :response))
        assert_nil(defaults.value(context: nil))
      end
    end
  end
end
