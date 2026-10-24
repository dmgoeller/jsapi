# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class OperationWrapperTest < Minitest::Test
      # Finders

      %i[find_response_for find_response_for!].each do |symbol|
        define_method(:"test_#{symbol}") do
          wrapper = Operation::Wrapper.new(
            operation = Operation.new(
              nil,
              responses: {
                'default' => {},
                '4xx' => {},
                404 => {}
              }
            ),
            API.new
          )
          {
            200 => Status::DEFAULT,
            400 => Status::Range::CLIENT_ERROR,
            404 => Status::Code.from(:not_found)
          }.each do |status_code, status|
            assert(
              expected = operation.response(status).equal?(
                actual = wrapper.send(symbol, status_code).__getobj__
              ),
              "Expected ##{symbol} to return #{expected.inspect} on #{status}, " \
              "is: #{actual.inspect}."
            )
          end
        end
      end

      def test_find_response_for_returns_nil_if_no_response_matchtes
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, responses: { 200 => {} }),
          API.new
        )
        assert_nil(wrapper.find_response_for(400))
      end

      def test_find_response_for_bang_raises_an_error_if_no_response_matches
        wrapper = Operation::Wrapper.new(
          Operation.new('foo'),
          API.new
        )
        error = assert_raises(ResponseNotFound) do
          wrapper.find_response_for!(400)
        end
        assert_equal('"foo" has no responses', error.message)

        wrapper = Operation::Wrapper.new(
          Operation.new('foo', responses: { 200 => {} }),
          API.new
        )
        error = assert_raises(ResponseNotFound) do
          wrapper.find_response_for!(400)
        end
        assert_equal('"foo" has no response for status 400', error.message)
      end

      # Model

      def test_model
        api_definition = API.new(
          paths: {
            '/foo' => { model: Class.new }
          }
        )
        # Operation with model
        operation = Operation.new(nil, path: '/foo', model: Class.new)
        assert_equal(
          operation.model,
          Operation::Wrapper.new(operation, api_definition).model
        )
        # Operation without model
        operation = Operation.new(nil, path: '/foo')
        assert_equal(
          api_definition.path('/foo').model,
          Operation::Wrapper.new(operation, api_definition).model
        )
      end

      def test_model_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, model: Class.new),
          API.new
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
          api_definition = API.new(
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
        assert_equal(api_definition.path('/foo').parameter('bar'), parameter.__getobj__)
      end

      def test_parameter_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, parameters: { 'foo' => {} }),
          API.new
        )
        parameters = wrapper.parameters['foo']
        assert(parameters.equal?(wrapper.parameters['foo']))
      end

      # Request body

      def test_request_body
        api_definition = API.new(
          paths: {
            '/foo' => { request_body: {} }
          }
        )
        # Operation with request body
        operation = Operation.new(nil, path: '/foo', request_body: {})
        request_body = Operation::Wrapper.new(operation, api_definition).request_body

        assert_kind_of(RequestBody::Wrapper, request_body)
        assert_equal(operation.request_body, request_body.__getobj__)

        # Operation without request body
        operation = Operation.new(nil, path: '/foo')
        request_body = Operation::Wrapper.new(operation, api_definition).request_body

        assert_kind_of(RequestBody::Wrapper, request_body)
        assert_equal(api_definition.path('/foo').request_body, request_body.__getobj__)
      end

      def test_request_body_caching
        wrapper = Operation::Wrapper.new(
          Operation.new(nil, request_body: {}),
          API.new
        )
        request_body = wrapper.request_body
        assert(request_body.equal?(wrapper.request_body))
      end

      # Responses

      def test_responses
        wrapper = Operation::Wrapper.new(
          operation = Operation.new(
            nil,
            path: '/foo',
            responses: {
              'default' => {}
            }
          ),
          api_definition = API.new(
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
        assert_equal(api_definition.path('/foo').response('4xx'), response.__getobj__)

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
          API.new
        )
        response = wrapper.responses[Status::DEFAULT]
        assert(response.equal?(wrapper.responses[Status::DEFAULT]))
      end

      # Security requirements

      def test_security_requirements
        api_definition = API.new(
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
              .new(operation, api_definition)
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
          API.new
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
