# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class OperationWrapperTest < Minitest::Test
      # #model

      def test_model
        definitions = Definitions.new(
          paths: {
            '/foo' => { model: Class.new }
          }
        )
        operation = Operation.new(nil, path: '/foo', model: Class.new)
        assert_equal(
          operation.model,
          Operation::Wrapper.new(operation, definitions).model
        )
        operation = Operation.new(nil, path: '/foo')
        assert_equal(
          definitions.path('/foo').model,
          Operation::Wrapper.new(operation, definitions).model
        )
      end

      def test_model_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, model: Class.new),
          Definitions.new
        )
        model = wrapper.model
        assert(model.eql?(wrapper.model))
      end

      # #parameters

      def test_parameters
        parameters = Operation::Wrapper.new(
          operation = Operation.new(
            nil,
            path: '/foo',
            parameters: { 'foo' => {} }
          ),
          definitions = Definitions.new(
            paths: {
              '/foo' => {
                parameters: { 'bar' => {} }
              }
            }
          )
        ).parameters

        parameter = parameters['foo']
        assert_kind_of(Parameter::Wrapper, parameter)
        assert_equal(operation.parameter('foo'), parameter.__getobj__)

        parameter = parameters['bar']
        assert_kind_of(Parameter::Wrapper, parameter)
        assert_equal(definitions.path('/foo').parameter('bar'), parameter.__getobj__)
      end

      def test_parameter_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, parameters: { 'foo' => {} }),
          Definitions.new
        )
        parameters = wrapper.parameters
        assert(parameters.eql?(wrapper.parameters))
      end

      # #request_body

      def test_request_body
        definitions = Definitions.new(
          paths: {
            '/foo' => { request_body: {} }
          }
        )
        operation = Operation.new(nil, path: '/foo', request_body: {})
        request_body = Operation::Wrapper.new(operation, definitions).request_body

        assert_kind_of(RequestBody::Wrapper, request_body)
        assert_equal(operation.request_body, request_body.__getobj__)

        operation = Operation.new(nil, path: '/foo')
        request_body = Operation::Wrapper.new(operation, definitions).request_body

        assert_kind_of(RequestBody::Wrapper, request_body)
        assert_equal(definitions.path('/foo').request_body, request_body.__getobj__)
      end

      def test_request_body_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, request_body: {}),
          Definitions.new
        )
        request_body = wrapper.request_body
        assert(request_body.eql?(wrapper.request_body))
      end

      # #response

      def test_response
        wrapper = Operation::Wrapper.new(
          operation = Operation.new(
            nil,
            path: '/foo',
            responses: {
              200 => {}
            }
          ),
          definitions = Definitions.new(
            paths: {
              '/foo' => {
                responses: {
                  400 => {}
                }
              }
            }
          )
        )
        response = wrapper.response(200)
        assert_kind_of(Response::Wrapper, response)
        assert_equal(operation.response(200), response.__getobj__)

        response = wrapper.response(400)
        assert_kind_of(Response::Wrapper, response)
        assert_equal(definitions.path('/foo').response(400), response.__getobj__)

        assert_nil(wrapper.response(500))
      end

      def test_response_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(
            nil,
            responses: {
              200 => {}
            }
          ),
          Definitions.new
        )
        response = wrapper.response(200)
        assert(response.eql?(wrapper.response(200)))
      end
    end
  end
end
