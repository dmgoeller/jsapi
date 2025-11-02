# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      class OAuth2Test < Minitest::Test
        include OpenAPITestHelper

        def test_minimal_openapi_security_scheme_object
          security_scheme = OAuth2.new

          each_openapi_version do |version|
            assert_openapi_equal(
              { type: 'oauth2' },
              security_scheme,
              version
            )
          end
        end

        def test_full_openapi_security_scheme_object
          security_scheme = OAuth2.new(
            description: 'Foo',
            oauth_flows: {
              implicit: {
                authorization_url: 'https://foo.bar/api/oauth/dialog'
              }
            },
            oauth2_metadata_url: 'https://foo.bar/api/oauth/metadata',
            deprecated: true,
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  type: 'oauth2',
                  description: 'Foo',
                  flow: 'implicit',
                  authorizationUrl: 'https://foo.bar/api/oauth/dialog',
                  scopes: {},
                  'x-foo': 'bar'
                }
              when OpenAPI::V3_0, OpenAPI::V3_1
                {
                  type: 'oauth2',
                  description: 'Foo',
                  flows: {
                    implicit: {
                      authorizationUrl: 'https://foo.bar/api/oauth/dialog',
                      scopes: {}
                    }
                  },
                  'x-foo': 'bar'
                }
              else
                {
                  type: 'oauth2',
                  description: 'Foo',
                  flows: {
                    implicit: {
                      authorizationUrl: 'https://foo.bar/api/oauth/dialog',
                      scopes: {}
                    }
                  },
                  oauth2MetadataUrl: 'https://foo.bar/api/oauth/metadata',
                  deprecated: true,
                  'x-foo': 'bar'
                }
              end,
              security_scheme,
              version
            )
          end
        end

        def test_openapi_security_schema_object_on_device_authorization
          security_scheme = OAuth2.new(
            oauth_flows: {
              device_authorization: {
                device_authorization_url: 'https://foo.bar/api/oauth/authorization'
              }
            }
          )
          each_openapi_version do |version|
            assert_equal(
              if version < OpenAPI::V3_2
                { type: 'oauth2' }
              else
                {
                  type: 'oauth2',
                  flows: {
                    deviceAuthorization: {
                      deviceAuthorizationUrl: 'https://foo.bar/api/oauth/authorization',
                      scopes: {}
                    }
                  }
                }
              end,
              security_scheme.to_openapi(version)
            )
          end
        end
      end
    end
  end
end
