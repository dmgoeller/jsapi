# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    class RequestParametersTest < Minitest::Test
      def test_bracket_operators
        params = Request::Parameters.new
        names = %w[FooBar fooBar foo_bar]

        names.each do |writer_name|
          params[writer_name] = 'baz'

          names.each do |reader_name|
            assert_equal('baz', params[reader_name])
          end
        end
      end

      def test_raises_an_error_if_name_is_nil
        params = Request::Parameters.new

        error = assert_raises(ArgumentError) do
          params[nil] = 'foo'
        end
        assert_equal("name can't be blank", error.message)
      end

      def test_raises_an_error_if_name_is_empty
        params = Request::Parameters.new

        error = assert_raises(ArgumentError) do
          params[''] = 'foo'
        end
        assert_equal("name can't be blank", error.message)
      end

      # Inspection

      def test_inspect
        params = Request::Parameters.new
        class_name = params.class.name

        assert_equal("#<#{class_name}>", params.inspect)

        params['foo'] = nil
        assert_equal("#<#{class_name} foo: nil>", params.inspect)

        params['bar'] = 'baz'
        assert_equal("#<#{class_name} bar: \"baz\", foo: nil>", params.inspect)
      end
    end
  end
end
