# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ServerTest < Minitest::Test
      include OpenAPITestHelper

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
