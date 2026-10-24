# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    class RequestHeadersTest < Minitest::Test
      def test_set_and_reset_header
        headers = Request::Headers.new

        # Set header
        headers['x-foo'] = 'bar'
        assert_equal(headers['x-foo'], 'bar')
        assert_equal([%w[x-foo bar]], headers.each.to_a)

        # Reset header
        headers['x-foo'] = nil
        assert_nil(headers['x-foo'])
        assert_predicate(headers.each.to_a, :empty?)
      end

      def test_names_are_case_insensitive
        names = %w[X-FOO X-Foo x-foo]

        names.each do |name_on_write|
          headers = Request::Headers.new
          headers[name_on_write] = 'bar'

          names.each do |name_on_read|
            assert_equal('bar', headers[name_on_read])
          end
        end
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

      # Inspection

      def test_inspect
        headers = Request::Headers.new
        class_name = headers.class.name

        assert_equal("#<#{class_name}>", headers.inspect)

        headers['x-foo'] = ''
        assert_equal("#<#{class_name} x-foo: \"\">", headers.inspect)

        headers['x-bar'] = 'baz'
        assert_equal("#<#{class_name} x-bar: \"baz\", x-foo: \"\">", headers.inspect)
      end
    end
  end
end
