# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      class OpenIDConnectTest < Minitest::Test
        include OpenAPITestHelper

        def test_minimal_openapi_security_scheme_object
          security_scheme = OpenIDConnect.new

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                nil
              else
                { type: 'openIdConnect' }
              end,
              security_scheme,
              version
            )
          end
        end

        def test_full_openapi_security_scheme_object
          security_scheme = OpenIDConnect.new(
            open_id_connect_url: 'https://foo.bar/openid',
            description: 'Foo',
            deprecated: true,
            openapi_extensions: { 'foo' => 'bar' }
          )
          expected_openapi_security_scheme_object = {
            type: 'openIdConnect',
            openIdConnectUrl: 'https://foo.bar/openid',
            description: 'Foo',
            'x-foo': 'bar'
          }
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                nil
              when OpenAPI::V3_0, OpenAPI::V3_1
                expected_openapi_security_scheme_object
              else
                expected_openapi_security_scheme_object.merge(
                  deprecated: true
                )
              end,
              security_scheme,
              version
            )
          end
        end
      end
    end
  end
end
