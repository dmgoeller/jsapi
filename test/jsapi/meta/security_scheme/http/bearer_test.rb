# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        class BearerTest < Minitest::Test
          include OpenAPITestHelper

          def test_minimal_openapi_security_scheme_object
            security_scheme = Bearer.new

            each_openapi_version do |version|
              assert_openapi_equal(
                if version == OpenAPI::V2_0
                  nil
                else
                  {
                    type: 'http',
                    scheme: 'bearer'
                  }
                end,
                security_scheme,
                version
              )
            end
          end

          def test_full_openapi_security_scheme_object
            security_scheme = Bearer.new(
              bearer_format: 'JWT',
              description: 'Foo',
              deprecated: true,
              openapi_extensions: { 'foo' => 'bar' }
            )
            each_openapi_version do |version|
              assert_openapi_equal(
                case version
                when OpenAPI::V2_0
                  nil
                when OpenAPI::V3_0, OpenAPI::V3_1
                  {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Foo',
                    'x-foo': 'bar'
                    }
                else
                  {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Foo',
                    deprecated: true,
                    'x-foo': 'bar'
                  }
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
end
