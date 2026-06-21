# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class WrapperTest < Minitest::Test
        include WrapperTestHelper

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
            ['BaseRef', true] => Existence::PRESENT
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

        def test_jsonify
          wrapper = Wrapper.new(
            String.new,
            Definitions.new(
              defaults: {
                'string' => { within_responses: '' }
              }
            )
          )

          ['foo', '', nil].each do |value|
            assert_json_equal(value, wrapper, value)
          end

          assert_json_equal('', wrapper, nil, context: :response)
        end

        def test_jsonify_on_non_nullable_schema
          wrapper = Wrapper.new(String.new(existence: :allow_empty), Definitions.new)

          ['foo', ''].each do |value|
            assert_json_equal(value, wrapper, value)
          end

          error = assert_raises(JsonifyError) { wrapper.jsonify(nil) }
          assert_equal("can't be nil", error.message)
        end
      end
    end
  end
end
