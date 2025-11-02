# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Link
      class BaseTest < Minitest::Test
        include OpenAPITestHelper

        def test_empty_openapi_link_object
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            link = Base.new
            assert_openapi_equal({}, link, version)
          end
        end

        def test_full_openapi_link_object
          link = Base.new(
            operation_id: 'foo',
            parameters: {
              'bar' => nil
            },
            request_body: 'bar',
            description: 'Lorem ipsum',
            server: {
              url: 'https://foo.bar/foo',
              name: 'production'
            },
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                operationId: 'foo',
                parameters: {
                  'bar' => nil
                },
                requestBody: 'bar',
                description: 'Lorem ipsum',
                server:
                  if version < OpenAPI::V3_2
                    { url: 'https://foo.bar/foo' }
                  else
                    {
                      url: 'https://foo.bar/foo',
                      name: 'production'
                    }
                  end,
                'x-foo': 'bar'
              },
              link,
              version
            )
          end
        end
      end
    end
  end
end
