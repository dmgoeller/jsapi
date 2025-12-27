# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        class BasicTest < Minitest::Test
          include TestHelper

          def test_minimal_openapi_security_scheme_object
            security_scheme = Basic.new

            each_openapi_version do |version|
              assert_openapi_equal(
                if version == OpenAPI::V2_0
                  { type: 'basic' }
                else
                  { type: 'http', scheme: 'basic' }
                end,
                security_scheme,
                version
              )
            end
          end

          def test_full_openapi_security_scheme_object
            security_scheme = Basic.new(
              description: 'Foo',
              deprecated: true,
              openapi_extensions: { 'foo' => 'bar' }
            )
            each_openapi_version do |version|
              assert_openapi_equal(
                case version
                when OpenAPI::V2_0
                  {
                    type: 'basic',
                    description: 'Foo',
                    'x-foo': 'bar'
                  }
                when OpenAPI::V3_0, OpenAPI::V3_1
                  {
                    type: 'http',
                    scheme: 'basic',
                    description: 'Foo',
                    'x-foo': 'bar'
                  }
                else
                  {
                    type: 'http',
                    scheme: 'basic',
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
