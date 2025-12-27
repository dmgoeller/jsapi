# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class OAuthFlowTest < Minitest::Test
      include TestHelper

      def test_minimal_openapi_oauth_flow_object
        each_openapi_version do |version|
          assert_equal({ scopes: {} }, OAuthFlow.new.to_openapi(version))
        end
      end

      def test_full_openapi_oauth_flow_object
        oauth_flow = OAuthFlow.new(
          authorization_url: 'https://foo.bar/api/oauth/dialog',
          device_authorization_url: 'https://foo.bar/api/oauth/device/code',
          token_url: 'https://foo.bar/api/oauth/token',
          refresh_url: 'https://foo.bar/api/oauth/refresh',
          scopes: {
            'read:foo' => nil,
            'write:foo' => { description: 'Lorem ipsum' }
          },
          openapi_extensions: { 'foo' => 'bar' }
        )
        openapi_oauth_flow_object = {
          authorizationUrl: 'https://foo.bar/api/oauth/dialog',
          deviceAuthorizationUrl: 'https://foo.bar/api/oauth/device/code',
          tokenUrl: 'https://foo.bar/api/oauth/token',
          refreshUrl: 'https://foo.bar/api/oauth/refresh',
          scopes: {
            'read:foo' => '',
            'write:foo' => 'Lorem ipsum'
          },
          'x-foo': 'bar'
        }
        each_openapi_version do |version|
          assert_openapi_equal(
            case version
            when OpenAPI::V2_0
              openapi_oauth_flow_object.except(:deviceAuthorizationUrl, :refreshUrl)
            when OpenAPI::V3_0, OpenAPI::V3_1
              openapi_oauth_flow_object.except(:deviceAuthorizationUrl)
            else
              openapi_oauth_flow_object
            end,
            oauth_flow,
            version
          )
        end
      end
    end
  end
end
