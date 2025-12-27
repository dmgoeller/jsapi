# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class ServerVariableTest < Minitest::Test
      include TestHelper

      def test_empty_openapi_server_variable_object
        server_variable = ServerVariable.new

        assert_openapi_equal({}, server_variable, nil)
      end

      def test_full_openapi_server_object
        server_variable = ServerVariable.new(
          enum: %w[foo bar],
          default: 'foo',
          description: 'Foo',
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_openapi_equal(
          {
            enum: %w[foo bar],
            default: 'foo',
            description: 'Foo',
            'x-foo': 'bar'
          },
          server_variable,
          nil
        )
      end
    end
  end
end
