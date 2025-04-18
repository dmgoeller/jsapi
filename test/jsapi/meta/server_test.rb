# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ServerTest < Minitest::Test
      def test_empty_openapi_server_object
        assert_equal({}, Server.new.to_openapi)
      end

      def test_full_openapi_server_object
        server = Server.new(
          description: 'Foo',
          url: 'https://{subdomain}.foo.bar',
          variables: {
            'subdomain' => { default: 'api' }
          },
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_equal(
          {
            description: 'Foo',
            url: 'https://{subdomain}.foo.bar',
            variables: {
              'subdomain' => {
                default: 'api'
              }
            },
            'x-foo': 'bar'
          },
          server.to_openapi
        )
      end
    end
  end
end
