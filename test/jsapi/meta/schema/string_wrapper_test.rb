# frozen_string_literal: true

require 'test_helper'

require_relative 'wrapper_test_helper'

module Jsapi
  module Meta
    module Schema
      class StringWrapperTest < Minitest::Test
        include WrapperTestHelper

        def test_jsonify
          wrapper = wrap_schema

          assert_json_equal('true', wrapper, 'true')
          assert_json_equal('true', wrapper, true)
          assert_json_equal(nil, wrapper, nil)
        end

        def test_jsonify_on_schema_with_date_format
          wrapper = wrap_schema(format: 'date')

          ['2099-12-31', Date.new(2099, 12, 31)].each do |value|
            assert_json_equal('2099-12-31', wrapper, value)
          end
        end

        def test_jsonify_on_schema_with_datetime_format
          wrapper = wrap_schema(format: 'date-time')

          ['2099-12-31', Date.new(2099, 12, 31)].each do |value|
            assert_json_equal('2099-12-31T00:00:00.000+00:00', wrapper, value)
          end
        end

        def test_jsonify_on_schema_with_duration_format
          wrapper = wrap_schema(format: 'duration')

          ['P1D', ActiveSupport::Duration.build(86_400)].each do |value|
            assert_json_equal('P1D', wrapper, value)
          end
        end

        def test_jsonify_on_schema_with_conversion
          wrapper = wrap_schema(conversion: :upcase)

          assert_json_equal('FOO', wrapper, 'Foo')
        end
      end
    end
  end
end
