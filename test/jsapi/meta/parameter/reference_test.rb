# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Parameter
      class ReferenceTest < Minitest::Test
        include TestHelper

        # #openapi_parameters

        def test_openapi_parameters
          definitions = Definitions.new(
            parameters: {
              'foo' => { type: 'string' }
            }
          )
          reference = Reference.new(ref: 'foo')

          each_openapi_version do |version|
            assert_equal(
              [
                if version < OpenAPI::V3_0
                  { '$ref': '#/parameters/foo' }
                else
                  { '$ref': '#/components/parameters/foo' }
                end
              ],
              reference.to_openapi_parameters(version, definitions)
            )
          end
        end

        def test_openapi_parameters_on_object
          definitions = Definitions.new(
            parameters: {
              'foo' => {
                type: 'object',
                properties: {
                  'bar' => { type: 'string' }
                }
              }
            }
          )
          reference = Reference.new(ref: 'foo')

          each_openapi_version do |version|
            assert_equal(
              [
                case version
                when OpenAPI::V2_0
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    type: 'string',
                    allowEmptyValue: true
                  }
                when OpenAPI::V3_0
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    schema: {
                      type: 'string',
                      nullable: true
                    },
                    allowEmptyValue: true
                  }
                else
                  {
                    name: 'foo[bar]',
                    in: 'query',
                    schema: {
                      type: %w[string null]
                    },
                    allowEmptyValue: true
                  }
                end
              ],
              reference.to_openapi_parameters(version, definitions)
            )
          end
        end
      end
    end
  end
end
