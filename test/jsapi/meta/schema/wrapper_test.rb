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

        def test_existence
          definitions = Definitions.new(
            schemas: {
              'Base' => {},
              'BaseRef' => {
                ref: 'Base',
                existence: :allow_empty
              }
            }
          )
          {
            ['Base', false] => Existence::ALLOW_OMITTED,
            ['Base', true] => Existence::PRESENT,
            ['BaseRef', false] => Existence::ALLOW_EMPTY,
            ['BaseRef', true] => Existence::PRESENT,
          }.each do |(ref, existence), expected|
            wrapper = Wrapper.new(
              Reference.new(ref: ref, existence: existence),
              definitions
            )
            assert(
              expected == actual = wrapper.existence,
              "Expected level of existence of #{wrapper.inspect} " \
              "to be #{expected.inspect}, is: #{actual.inspect}."
            )
          end
        end
      end
    end
  end
end
