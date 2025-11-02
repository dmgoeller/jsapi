# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module OpenAPI
      class PathItemTest < Minitest::Test
        include OpenAPITestHelper

        def test_openapi_path_item_object
          openapi_path_item = PathItem.new(
            %w[GET TRACE QUERY CUSTOM].map do |method|
              Operation.new("#{method.downcase}_operation", method: method)
            end
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  'get' => {
                    operationId: 'get_operation',
                    parameters: [],
                    responses: {}
                  }
                }
              when OpenAPI::V3_0, OpenAPI::V3_1
                {
                  'get' => {
                    operationId: 'get_operation',
                    parameters: [],
                    responses: {}
                  },
                  'trace' => {
                    operationId: 'trace_operation',
                    parameters: [],
                    responses: {}
                  }
                }
              else
                {
                  'get' => {
                    operationId: 'get_operation',
                    parameters: [],
                    responses: {}
                  },
                  'trace' => {
                    operationId: 'trace_operation',
                    parameters: [],
                    responses: {}
                  },
                  'query' => {
                    operationId: 'query_operation',
                    parameters: [],
                    responses: {}
                  },
                  additionalOperations: {
                    'CUSTOM' => {
                      operationId: 'custom_operation',
                      parameters: [],
                      responses: {}
                    }
                  }
                }
              end,
              openapi_path_item,
              version,
              nil
            )
          end
        end
      end
    end
  end
end
