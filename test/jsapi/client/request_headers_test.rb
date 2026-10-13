# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    class RequestHeadersTest < Minitest::Test
      def test_bracket_operators
        headers = Request::Headers.new

        # Set header
        headers['X-Foo'] = 'bar'
        assert_equal('bar', headers['X-Foo'])
        assert_equal([%w[X-Foo bar]], headers.each.to_a)

        # Reset header
        headers['X-Foo'] = nil
        assert_nil(headers['X-Foo'])
        assert_empty(headers.each.to_a)
      end

      def test_raises_an_error_if_name_is_nil
        headers = Request::Headers.new

        error = assert_raises(ArgumentError) do
          headers[nil] = 'foo'
        end
        assert_equal("name can't be blank", error.message)
      end

      def test_raises_an_error_if_name_is_empty
        headers = Request::Headers.new

        error = assert_raises(ArgumentError) do
          headers[''] = 'foo'
        end
        assert_equal("name can't be blank", error.message)
      end

      # HTTP Basic authentication

      def test_http_basic_auth
        headers = Request::Headers.new
        headers.http_basic_auth('u', 'p')

        assert_equal('Basic dTpw', headers['Authorization'])
      end

      def test_http_basic_auth_with_empty_user_and_password
        headers = Request::Headers.new
        headers.http_basic_auth

        assert_equal('Basic Og==', headers['Authorization'])
      end

      # HTTP Bearer authentication

      def test_http_bearer
        headers = Request::Headers.new
        headers.http_bearer('foo')

        assert_equal('Bearer Zm9v', headers['Authorization'])
      end

      def test_raises_an_error_if_bearer_token_is_empty
        headers = Request::Headers.new

        error = assert_raises(ArgumentError) do
          headers.http_bearer('')
        end
        assert_equal("token can't be blank", error.message)
      end

      # Inspection

      def test_inspect
        headers = Request::Headers.new
        class_name = headers.class.name

        assert_equal("#<#{class_name}>", headers.inspect)

        headers['X-Foo'] = ''
        assert_equal("#<#{class_name} X-Foo: \"\">", headers.inspect)

        headers['X-Bar'] = 'baz'
        assert_equal("#<#{class_name} X-Bar: \"baz\", X-Foo: \"\">", headers.inspect)
      end
    end
  end
end
