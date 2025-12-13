# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      class APIKeyTest < Minitest::Test
        include TestHelper

        def test_minimal_openapi_security_scheme_object
          security_scheme = APIKey.new

          each_openapi_version do |version|
            assert_openapi_equal(
              { type: 'apiKey' },
              security_scheme,
              version
            )
          end
        end

        def test_full_openapi_security_scheme_object
          security_scheme = APIKey.new(
            name: 'X-API-Key',
            in: 'header',
            description: 'Foo',
            deprecated: true,
            openapi_extensions: { 'foo' => 'bar' }
          )
          expected_openapi_security_scheme_object = {
            type: 'apiKey',
            name: 'X-API-Key',
            in: 'header',
            description: 'Foo',
            'x-foo': 'bar'
          }
          each_openapi_version do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_2
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
