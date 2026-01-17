# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Controller
    class MethodsTest < Minitest::Test
      include TestHelper

      # #api_operation and #api_operation!

      %i[api_operation api_operation!].each do |method|
        name = method.to_s.sub('!', '_bang')

        define_method("test_#{name}_without_block") do
          controller = controller do
            api_operation do
              response type: 'string'
            end
          end
          response = controller.instance_eval do
            send(method, status: :ok)
            self.response
          end

          assert_equal(200, response.status)
          assert_equal('application/json', response.content_type)
          assert_equal('null', response.body)
        end

        define_method("test_#{name}_with_block") do
          controller = controller do
            api_operation do
              parameter 'foo', type: 'string'
              response type: 'string', content_type: 'text/plain'
            end
          end
          response = controller.instance_eval do
            params['foo'] = 'bar'
            send(method, status: :ok) do |api_params|
              "value of foo is #{api_params.foo}"
            end
            self.response
          end

          assert_equal(200, response.status)
          assert_equal('text/plain', response.content_type)
          assert_equal('value of foo is bar', response.body)
        end

        define_method("test_#{name}_with_authentication") do
          controller_class = controller_class do
            include Authentication

            api_authenticate do |credentials|
              credentials.api_key == 'foo'
            end

            api_after_authentication :after_authentication

            api_rescue_from Unauthorized, with: 401

            api_operation 'foo' do
              response type: 'string'
            end

            api_security_scheme 'api_key', type: 'api_key', in: 'header', name: 'X-API-KEY'
            api_security_requirement { scheme 'api_key' }

            def after_authentication(operation_name)
              checks << "after_authentication:#{operation_name}"
            end
          end

          # Request with valid credentials
          controller = controller_class.new

          controller.instance_eval do
            request.headers['X-API-KEY'] = 'foo'
            send(method, 'foo', status: :ok)
          end
          assert(
            controller.response.status == 200,
            'Expected request with valid credentials to be authenticated.'
          )
          assert(
            controller.checks.include?('after_authentication:foo'),
            'Expected api_after_authentication callback to be triggered ' \
            'when request has been authenticated.'
          )
          # Request with invalid credentials
          controller = controller_class.new

          controller.instance_eval do
            request.headers['X-API-KEY'] = 'bar'
            send(method, status: :ok)
          end
          assert(
            controller.response.status == 401,
            'Expected request with invalid credentials not to be authenticated.'
          )
          assert(
            controller.checks.exclude?('after_authentication'),
            'Expected api_after_authentication callback not to triggered ' \
            'when request has not been authenticated.'
          )
        end

        define_method("test_#{name}_raises_an_error_when_the_" \
                      'operation_could_not_be_found') do
          assert_raises(OperationNotFound) do
            controller.instance_eval { send(method, :foo) }
          end
        end

        define_method("test_#{name}_raises_an_error_when_no_suitable_" \
                      'response_could_be_found') do
          controller = controller do
            api_operation do
              response 200, type: 'string'
            end
          end
          assert_raises(ResponseNotFound) do
            controller.instance_eval { send(method, status: 204) }
          end
        end

        # Rendering

        define_method("test_#{name}_triggers_a_before_rendering_callback") do
          controller = controller do
            api_operation do
              parameter 'request_id', type: 'integer'
              response do
                property 'request_id', type: 'integer'
                property 'foo', type: 'string'
              end
            end

            api_before_rendering do |result, _operation_name, api_params|
              { request_id: api_params.request_id, foo: result }
            end
          end
          response = controller.instance_eval do
            params['request_id'] = 1
            send(method) { 'bar' }
            self.response
          end
          assert_equal('{"request_id":1,"foo":"bar"}', response.body)
        end

        # Responses

        define_method("test_#{name}_produces_a_json_response_" \
                      'if_content_type_is_application_json') do
          controller_class = controller_class do
            api_operation do
              response type: 'string', content_type: 'application/json'
            end
          end
          [200, 201].each do |status|
            response = controller_class.new.instance_eval do
              send(method, status: status) { 'foo' }
              self.response
            end
            assert_equal(status, response.status)
            assert_equal('application/json', response.content_type)
            assert_equal('"foo"', response.body)
          end
        end

        define_method("test_#{name}_produces_a_plain_response_" \
                      'if_content_type_is_text_plain') do
          controller_class = controller_class do
            api_operation do
              response type: 'string', content_type: 'text/plain'
            end
          end
          [200, 201].each do |status|
            response = controller_class.new.instance_eval do
              send(method, status: status) { 'foo' }
              self.response
            end
            assert_equal(status, response.status)
            assert_equal('text/plain', response.content_type)
            assert_equal('foo', response.body)
          end
        end

        define_method("test_#{name}_streams_a_json_object_" \
                      'if_content_type_is_application_json_seq') do
          controller_class = controller_class do
            api_operation do
              response type: 'string', content_type: 'application/json-seq'
            end
          end
          [200, 201].each do |status|
            response = controller_class.new.instance_eval do
              send(method, status: status) { 'foo' }
              self.response
            end
            assert_equal('application/json-seq', response.content_type)
            assert_equal("\u001E\"foo\"\n", response.stream.string)
            assert_predicate(response.stream, :closed?)
          end
        end

        define_method("test_#{name}_produces_an_empty_response_" \
                      'if_no_content_is_givem') do
          controller = controller do
            api_operation do
              response contents: {}
            end
          end
          response = controller.instance_eval do
            send(method, status: 204)
            self.response
          end
          assert_equal(204, response.status)
          assert_nil(response.content_type)
          assert_equal([''], response.body)
        end

        define_method("test_#{name}_produces_no_response_" \
                     'if_media_type_is_not_supported') do
          controller = controller do
            api_operation do
              response type: 'string', content_type: 'text/html'
            end
          end
          response = controller.instance_eval do
            send(method) { 'foo' }
            self.response
          end

          assert_nil(response.status)
          assert_nil(response.content_type)
          assert_nil(response.body)
        end

        define_method("test_#{name}_keeps_an_explictly_rendered_response") do
          controller = controller do
            api_operation do
              response type: 'string', content_type: 'application/json'
            end
          end
          response = controller.instance_eval do
            send(method, status: 200) do
              render plain: 'bar', status: 201, content_type: 'text/plain'
            end
            self.response
          end

          assert_equal(201, response.status)
          assert_equal('text/plain', response.content_type)
          assert_equal('bar', response.body)
        end

        # Content negotiation

        define_method("test_#{name}_produces_the_most_appropriate_response") do
          controller_class = controller_class do
            api_operation do
              response do
                content 'application/json', type: 'string'
                content 'text/plain', type: 'string'
              end
            end
          end
          application_json = ['application/json', '"foo"']
          text_plain = ['text/plain', 'foo']
          {
            'application/json' => application_json,
            'application/*' => application_json,
            '*/*' => application_json,
            'text/plain' => text_plain,
            'text/*' => text_plain
          }.each do |media_range, (media_type, response_body)|
            controller = controller_class.new(
              request_headers: { 'Accept' => media_range }
            )
            response = controller.instance_eval do
              send(method) { 'foo' }
              self.response
            end
            assert(
              response.content_type = media_type,
              "Expected #{media_type.inspect} to be the most appropriate " \
              "media type for #{media_range.inspect}"
            )
            assert(
              response.body == response_body,
              "Expected #{response_body.inspect} to be the most appropriate " \
              "response body for #{media_range.inspect}"
            )
          end
        end

        # Error handling

        define_method("test_#{name}_produces_an_error_response_when_rescuing_an_exception") do
          controller = controller do
            api_definitions do
              rescue_from RuntimeError, with: 500

              operation do
                response type: 'string'
                response '5xx', type: 'string', content_type: 'application/problem+json'
              end
            end
          end
          response = controller.instance_eval do
            send(method) { raise 'foo' }
            self.response
          end

          assert_equal(500, response.status)
          assert_equal('application/problem+json', response.content_type)
          assert_equal('"foo"', response.body)
        end

        define_method("test_#{name}_calls_an_on_rescue_callback_as_a_method") do
          controller = controller do
            api_definitions do
              rescue_from RuntimeError, with: 500
              on_rescue :notice_error

              operation do
                response type: 'string'
                response '5xx', type: 'string'
              end
            end

            attr_reader :error

            def notice_error(error)
              @error = error
            end
          end
          error = controller.instance_eval do
            send(method) { raise 'foo' }
            self.error
          end

          assert_kind_of(RuntimeError, error)
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_calls_an_on_rescue_callback_as_a_block") do
          error = nil

          controller = controller do
            api_definitions do
              rescue_from RuntimeError, with: 500
              on_rescue { |e| error = e }

              operation do
                response type: 'string'
                response '5xx', type: 'string'
              end
            end
          end
          controller.instance_eval do
            send(method) { raise 'foo' }
          end

          assert_kind_of(RuntimeError, error)
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_reraises_an_error") do
          controller = controller do
            api_definitions do
              rescue_from RuntimeError, with: 500

              operation do
                response 200, type: 'string'
              end
            end
          end
          error = assert_raises(RuntimeError) do
            controller.instance_eval do
              send(method, status: 200) { raise 'foo' }
            end
          end
          assert_equal('foo', error.message)
        end
      end

      def test_api_operation_on_strong_parameters
        controller_class = controller_class do
          api_operation do
            parameter 'foo', type: 'string'
            response type: 'string'
          end
        end
        # Good request
        controller = controller_class.new(
          params: {
            foo: 'bar',
            controller: 'Foo',
            action: 'bar',
            format: 'application/json'
          }
        )
        controller.api_operation(strong: true) do |api_params|
          assert_predicate(api_params, :valid?)
        end

        # Bad request
        controller = controller_class.new(params: { bar: 'foo' })

        controller.api_operation(strong: true) do |api_params|
          assert_predicate(api_params, :invalid?)
          assert(api_params.errors.added?(:base, "'bar' isn't allowed"))
        end
      end

      def test_api_operation_bang_on_strong_parameters
        controller_class = controller_class do
          api_operation do
            parameter 'foo', type: 'string'
            response type: 'string'
          end
        end
        # Good request
        controller = controller_class.new(
          params: {
            foo: 'bar',
            controller: 'Foo',
            action: 'bar',
            format: 'application/json'
          }
        )
        controller.api_operation!(strong: true) do |api_params|
          assert_predicate(api_params, :valid?)
        end

        # Bad request
        controller = controller_class.new(params: { bar: 'foo ' })

        error = assert_raises Jsapi::Controller::ParametersInvalid do
          controller.api_operation!(strong: true) do
            assert(false) # Expected this line not to be reached
          end
        end
        assert_equal("'bar' isn't allowed.", error.message)
      end

      def test_api_operation_bang_triggers_after_validation_callbacks
        controller_class = controller_class do
          api_after_validation :after_validation

          api_rescue_from ParametersInvalid, with: 400

          api_operation do
            parameter 'foo', type: 'string', enum: %w[foo bar]
            response type: 'string'
          end

          def after_validation(_api_params)
            checks << 'after_validation'
          end
        end
        assert(
          controller_class.new.instance_eval do
            params['foo'] = 'bar'
            api_operation!(status: 200) {}
            checks
          end.include?('after_validation'),
          'Expected api_after_validation callback to be triggered ' \
          'when parameters are valid.'
        )
        assert(
          controller_class.new.instance_eval do
            params['foo'] = 'baz'
            api_operation!(status: 200) {}
            checks
          end.exclude?('after_validation'),
          'Expected api_after_validation callback not to be triggered ' \
          'when parameters are invalid.'
        )
      end

      # #api_params

      def test_api_params
        controller = controller do
          api_operation do
            parameter 'foo', type: 'string'
            response type: 'string'
          end
        end
        controller.params['foo'] = 'bar'
        assert_equal(
          'bar',
          controller.instance_eval { api_params.foo }
        )
      end

      def test_api_params_on_strong_parameters
        controller_class = controller_class do
          api_operation do
            parameter 'foo', type: 'string'
            response type: 'string'
          end
        end
        # Good request
        controller = controller_class.new(
          params: {
            foo: 'bar',
            controller: 'Foo',
            action: 'bar',
            format: 'application/json'
          }
        )
        api_params = controller.instance_eval do
          api_params(strong: true)
        end
        assert_predicate(api_params, :valid?)

        # Bad request
        controller = controller_class.new(params: { bar: 'foo' })

        api_params = controller.instance_eval do
          api_params(strong: true)
        end
        assert_predicate(api_params, :invalid?)
        assert(api_params.errors.added?(:base, "'bar' isn't allowed"))
      end

      def test_api_params_raises_an_error_when_the_operation_could_not_be_found
        assert_raises(OperationNotFound) do
          controller.instance_eval { api_params('foo') }
        end
      end

      # #api_response

      def test_api_response
        controller = controller do
          api_operation do
            response type: 'string'
          end
        end
        response = controller.instance_eval do
          api_response('foo')
        end
        assert_equal('"foo"', response.to_json)
      end

      def test_api_response_takes_the_most_appropriate_media_type
        controller_class = controller_class do
          api_operation do
            response do
              content 'application/vnd.str+json', type: 'string'
              content 'application/vnd.int+json', type: 'integer'
            end
          end
        end
        {
          'application/vnd.str+json' => '"88"',
          'application/vnd.int+json' => '88'
        }.each do |media_type, expected|
          controller = controller_class.new(
            request_headers: { 'Accept' => media_type }
          )
          response = controller.instance_eval do
            api_response(88)
          end.to_json
          assert(
            expected == response,
            "Expected #{expected.inspect} to be the most appropriate response " \
            "body for #{media_type.inspect}, is: #{response.inspect}."
          )
        end
      end

      def test_api_response_raises_an_error_when_the_operation_could_not_be_found
        assert_raises(OperationNotFound) do
          controller.instance_eval do
            api_response('foo', 'foo', status: 200)
          end
        end
      end

      def test_api_response_raises_an_error_when_no_suitable_response_could_be_found
        controller = controller do
          api_operation do
            response 200, type: 'string'
          end
        end
        assert_raises(ResponseNotFound) do
          controller.instance_eval do
            controller.api_response('foo', status: 204)
          end
        end
      end
    end
  end
end
