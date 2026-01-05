# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Callback
      class BaseTest < Minitest::Test
        include TestHelper

        def test_add_expression
          callback = Base.new
          operations = callback.add_expression('{$request.query.foo}')
          assert(operations.equal?(callback.expression('{$request.query.foo}')))
        end

        def test_add_expression_raises_an_error_when_attributes_are_frozen
          callback = Base.new
          callback.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            callback.add_expression('{$request.query.foo}')
          end
        end

        def test_add_expression_raises_an_error_when_expression_is_blank
          callback = Base.new
          error = assert_raises(ArgumentError) do
            callback.add_expression('')
          end
          assert_equal("expression can't be blank", error.message)
        end

        def test_add_operation
          operations = Base.new(
            expressions: {
              '{$request.query.foo}' => {}
            }
          ).expression('{$request.query.foo}')

          operation = assert_difference('operations.operations.count', 1) do
            operations.add_operation description: 'Description for GET'
          end
          assert(operation.equal?(operations.operation('get')))
          assert_equal('Description for GET', operation.description)

          operation = assert_difference('operations.operations.count', 1) do
            operations.add_operation 'post', description: 'Description for POST'
          end
          assert(operation.equal?(operations.operation('post')))
          assert_equal('Description for POST', operation.description)
        end

        def test_add_operation_raises_an_error_when_attributes_are_frozen
          operations = Base.new(
            expressions: {
              '{$request.query.foo}' => {}
            }
          ).expression('{$request.query.foo}')

          operations.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            operations.add_operation
          end
        end

        def test_add_parameter
          operations = Base.new(
            expressions: {
              '{$request.query.foo}' => {}
            }
          ).expression('{$request.query.foo}')

          parameter = assert_difference('operations.parameters.count', 1) do
            operations.add_parameter('bar', type: 'string')
          end
          assert(parameter.equal?(operations.parameter('bar')))
          assert_equal('string', parameter.type)
        end

        def test_add_parameter_raises_an_error_when_attributes_are_frozen
          operations = Base.new(
            expressions: {
              '{$request.query.foo}' => {}
            }
          ).expression('{$request.query.foo}')

          operations.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            operations.add_parameter('bar')
          end
        end

        # OpenAPI callback objects

        def test_minimal_openapi_callback_object
          callback = Base.new

          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal({}, callback, version, Definitions.new)
          end
        end

        def test_full_openapi_callback_object
          callback = Base.new(
            expressions: {
              '{$request.query.foo}' => {
                description: 'Description of foo',
                summary: 'Summary of foo',
                parameters: {
                  'foo' => {
                    type: 'string',
                    existence: true
                  }
                },
                operations: {
                  'get' => {}
                }
              }
            }
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                '{$request.query.foo}' => {
                  description: 'Description of foo',
                  summary: 'Summary of foo',
                  parameters: [
                    {
                      name: 'foo',
                      in: 'query',
                      schema: {
                        type: 'string'
                      },
                      required: true
                    }
                  ],
                  get: {
                    parameters: [],
                    responses: {}
                  }
                }
              },
              callback,
              version,
              Definitions.new
            )
          end
        end

        def test_openapi_callback_object_with_minimal_path_item_object
          callback = Base.new(
            expressions: {
              '{$request.query.foo}' => {}
            }
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                "{$request.query.foo}": {}
              },
              callback,
              version,
              Definitions.new
            )
          end
        end
      end
    end
  end
end
