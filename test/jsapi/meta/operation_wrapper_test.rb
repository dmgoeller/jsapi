# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class OperationWrapperTest < Minitest::Test
      # Model

      def test_model
        definitions = Definitions.new(
          paths: {
            '/foo' => { model: Class.new }
          }
        )
        # Operation with model
        operation = Operation.new(nil, path: '/foo', model: Class.new)
        assert_equal(
          operation.model,
          Operation::Wrapper.new(operation, definitions).model
        )
        # Operation without model
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
        assert(model.equal?(wrapper.model))
      end

      # Parameters

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
        parameters = wrapper.parameters['foo']
        assert(parameters.equal?(wrapper.parameters['foo']))
      end

      # Request body

      def test_request_body
        definitions = Definitions.new(
          paths: {
            '/foo' => { request_body: {} }
          }
        )
        # Operation with request body
        operation = Operation.new(nil, path: '/foo', request_body: {})
        request_body = Operation::Wrapper.new(operation, definitions).request_body

        assert_kind_of(RequestBody::Wrapper, request_body)
        assert_equal(operation.request_body, request_body.__getobj__)

        # Operation without request body
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
        assert(request_body.equal?(wrapper.request_body))
      end

      # Responses

      def test_find_response
        wrapper = Operation::Wrapper.new(
          operation = Operation.new(
            nil,
            responses: {
              'default' => {},
              '4xx' => {},
              404 => {}
            }
          ),
          Definitions.new
        )
        {
          200 => Status::DEFAULT,
          400 => Status::Range::CLIENT_ERROR,
          404 => Status::Code.from(:not_found)
        }.each do |status_code, status|
          assert(
            expected = operation.response(status).equal?(
              actual = wrapper.find_response(status_code).__getobj__
            ),
            "Expected #{actual} to be #{expected}."
          )
        end
      end

      def test_find_response_returns_nil_if_no_matching_response_exists
        wrapper = Operation::Wrapper.new(
          Operation.new(
            nil,
            responses: {
              200 => {}
            }
          ),
          Definitions.new
        )
        assert_nil(wrapper.find_response(400))
      end

      def test_responses
        wrapper = Operation::Wrapper.new(
          operation = Operation.new(
            nil,
            path: '/foo',
            responses: {
              'default' => {}
            }
          ),
          definitions = Definitions.new(
            paths: {
              '/foo' => {
                responses: {
                  '4xx' => {}
                }
              }
            }
          )
        )
        response = wrapper.responses[Status::DEFAULT]
        assert_kind_of(Response::Wrapper, response)
        assert_equal(operation.response('default'), response.__getobj__)

        response = wrapper.responses[Status::Range::CLIENT_ERROR]
        assert_kind_of(Response::Wrapper, response)
        assert_equal(definitions.path('/foo').response('4xx'), response.__getobj__)

        assert_nil(wrapper.responses[Status::Range::SERVER_ERROR])
      end

      def test_response_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(
            nil,
            responses: {
              'default' => {}
            }
          ),
          Definitions.new
        )
        response = wrapper.responses[Status::DEFAULT]
        assert(response.equal?(wrapper.responses[Status::DEFAULT]))
      end

      # Security requirements

      def test_security_requirements
        definitions = Definitions.new(
          paths: {
            '/foo' => {
              security_requirements: [
                { schemes: { 'path_sec_req' => nil } }
              ]
            }
          },
          security_requirements: [
            { schemes: { 'global_sec_req' => nil } }
          ]
        )
        {
          Operation.new(
            nil,
            path: '/foo',
            security_requirements: [
              { schemes: { 'operation_sec_req' => nil } }
            ]
          ) => %w[operation_sec_req path_sec_req],
          Operation.new(
            nil,
            security_requirements: [
              { schemes: { 'operation_sec_req' => nil } }
            ]
          ) => %w[operation_sec_req],
          Operation.new(
            nil,
            path: '/foo'
          ) => %w[path_sec_req],
          Operation.new(nil) => %w[global_sec_req]
        }.each do |operation, expected|
          assert_equal(
            expected,
            Operation::Wrapper
              .new(operation, definitions)
              .security_requirements
              .flat_map { |s| s.schemes.keys }
              .sort
          )
        end
      end

      def test_security_requirements_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(
            nil,
            security_requirements: [
              { schemes: { 'foo' => nil } }
            ]
          ),
          Definitions.new
        )
        security_requirements = wrapper.security_requirements
        assert(
          security_requirements.present? &&
            security_requirements.equal?(wrapper.security_requirements)
        )
      end
    end
  end
end
