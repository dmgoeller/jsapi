# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Definition
    class ServerTest < Minitest::Test
      include TestHelper

      def test_url_for
        server = Server.new(
          url: '{scheme}://foo.bar',
          variables: {
            'scheme' => {
              default: 'http',
              enum: %w[http https]
            }
          }
        )
        [{ 'scheme' => 'https' }, { scheme: 'https' }].each do |variables|
          url = server.url_for(variables)
          assert(
            url == 'https://foo.bar',
            "Expected URL for #{variables.inspect} to be" \
            "'https://foo.bar', is: #{url.inspect}"
          )
        end
        [{ 'scheme' => 'http' }, { scheme: 'http' }, {}, nil].each do |variables|
          url = server.url_for(variables)
          assert(
            url == 'http://foo.bar',
            "Expected URL for #{variables.inspect} to be" \
            "'http://foo.bar', is: #{url.inspect}"
          )
        end
        error = assert_raises(ArgumentError) do
          server.url_for({ scheme: 'wss' })
        end
        assert_equal('scheme must be one of "http" or "https", is "wss"', error.message)
      end

      def test_url_for_on_unknown_variable
        server = Server.new(url: '{scheme}://foo.bar')

        [{ 'scheme' => 'https' }, { scheme: 'https' }].each do |variables|
          url = server.url_for(variables)
          assert(
            url == 'https://foo.bar',
            "Expected URL for #{variables.inspect} to be" \
            "'https://foo.bar', is: #{url.inspect}"
          )
        end
        [{}, nil].each do |variables|
          url = server.url_for(variables)
          assert(
            url == '://foo.bar',
            "Expected URL for #{variables.inspect} to be" \
            "'://foo.bar', is: #{url.inspect}"
          )
        end
      end

      def test_url_for_returns_nil_if_url_is_nil
        assert_nil(Server.new.url_for({}))
      end

      # OpenAPI objects

      def test_empty_openapi_server_object
        server = Server.new

        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal({}, server, version)
        end
      end

      def test_full_openapi_server_object
        server = Server.new(
          description: 'Foo',
          url: 'https://{subdomain}.foo.bar',
          name: 'production',
          variables: {
            'subdomain' => { default: 'api' }
          },
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version(from: OpenAPI::V3_0) do |version|
          assert_openapi_equal(
            if version < OpenAPI::V3_2
              {
                description: 'Foo',
                url: 'https://{subdomain}.foo.bar',
                variables: {
                  'subdomain' => {
                    default: 'api'
                  }
                },
                'x-foo': 'bar'
              }
            else
              {
                description: 'Foo',
                url: 'https://{subdomain}.foo.bar',
                name: 'production',
                variables: {
                  'subdomain' => {
                    default: 'api'
                  }
                },
                'x-foo': 'bar'
              }
            end,
            server,
            version
          )
        end
      end
    end
  end
end
