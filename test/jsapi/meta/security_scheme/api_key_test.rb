# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      class APIKeyTest < Minitest::Test
        def test_minimal_openapi_security_scheme_object
          security_scheme = APIKey.new

          %w[2.0 3.0].each do |version|
            assert_equal(
              { type: 'apiKey' },
              security_scheme.to_openapi(version)
            )
          end
        end

        def test_full_openapi_security_scheme_object
          security_scheme = APIKey.new(
            name: 'X-API-Key',
            in: 'header',
            description: 'Foo',
            openapi_extensions: { 'foo' => 'bar' }
          )
          %w[2.0 3.0].each do |version|
            assert_equal(
              {
                type: 'apiKey',
                name: 'X-API-Key',
                in: 'header',
                description: 'Foo',
                'x-foo': 'bar'
              },
              security_scheme.to_openapi(version)
            )
          end
        end
      end
    end
  end
end
