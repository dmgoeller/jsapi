# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class WrapperTest < Minitest::Test
        def test_default_value
          wrapper = Wrapper.new(
            String.new(default: 'foo'),
            Definitions.new
          )
          assert_equal('foo', wrapper.default_value)
        end

        def test_default_value_on_general_default
          wrapper = Wrapper.new(
            String.new,
            Definitions.new(
              defaults: {
                'string' => {
                  within_requests: 'foo',
                  within_responses: 'bar'
                }
              }
            )
          )
          assert_equal('foo', wrapper.default_value(context: :request))
          assert_equal('bar', wrapper.default_value(context: :response))
        end
      end
    end
  end
end
