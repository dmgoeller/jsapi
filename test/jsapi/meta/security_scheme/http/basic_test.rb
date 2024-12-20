# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        class BasicTest < Minitest::Test
          def test_minimal_openapi_security_scheme_object
            security_scheme = Basic.new

            # OpenAPI 2.0
            assert_equal(
              { type: 'basic' },
              security_scheme.to_openapi('2.0')
            )
            # OpenAPI 3.0
            assert_equal(
              {
                type: 'http',
                scheme: 'basic'
              },
              security_scheme.to_openapi('3.0')
            )
          end

          def test_full_openapi_security_scheme_object
            security_scheme = Basic.new(
              description: 'Foo',
              openapi_extensions: { 'foo' => 'bar' }
            )
            # OpenAPI 2.0
            assert_equal(
              {
                type: 'basic',
                description: 'Foo',
                'x-foo': 'bar'
              },
              security_scheme.to_openapi('2.0')
            )
            # OpenAPI 3.0
            assert_equal(
              {
                type: 'http',
                scheme: 'basic',
                description: 'Foo',
                'x-foo': 'bar'
              },
              security_scheme.to_openapi('3.0')
            )
          end
        end
      end
    end
  end
end
