# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    class MethodsTest < Minitest::Test
      # #api_operation and #api_operation!

      %i[api_operation api_operation!].each do |method|
        name = method.to_s.gsub('!', '_bang')

        define_method("test_#{name}") do
          controller = dummy_controller do
            api_operation do
              response 200, type: 'string', content_type: 'application/vnd.foo+json'
            end
          end
          # Method call without block
          controller.send(method, status: 200)
          response = controller.response

          assert_equal(200, response.status)
          assert_nil(response.content_type)
          assert_nil(response.body)

          # Method call with block
          controller.send(method, status: 200) { 'foo' }
          response = controller.response

          assert_equal(200, response.status)
          assert_equal('application/vnd.foo+json', response.content_type)
          assert_equal('"foo"', response.body)

          # Errors
          error = assert_raises(RuntimeError) do
            controller.send(method, :foo)
          end
          assert_equal('operation not defined: foo', error.message)

          error = assert_raises(RuntimeError) do
            controller.send(method, status: 204)
          end
          assert_equal('status code not defined: 204', error.message)

          error = assert_raises(RuntimeError) do
            controller.send(method, status: 200) { raise 'foo' }
          end
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_passes_params_to_the_block") do
          controller = dummy_controller do
            api_operation do
              parameter 'foo', type: 'string'
              response 200, type: 'string'
            end
          end
          controller.params['foo'] = 'bar'

          controller.send(method, status: 200) do |api_params|
            assert_equal('bar', api_params.foo)
          end
        end

        define_method("test_#{name}_renders_an_error_response_when_rescuing_an_exception") do
          controller = dummy_controller do
            api_definitions do
              rescue_from RuntimeError, with: 500

              operation do
                response 200, type: 'string'
                response 500, type: 'string', content_type: 'application/problem+json'
              end
            end
          end
          controller.send(method, status: 200) { raise 'foo' }
          response = controller.response

          assert_equal(500, response.status)
          assert_equal('application/problem+json', response.content_type)
          assert_equal('"foo"', response.body)
        end

        define_method("test_#{name}_calls_an_on_rescue_callback_as_a_method") do
          controller = dummy_controller do
            api_definitions do
              rescue_from RuntimeError, with: 500
              on_rescue :notice_error

              operation do
                response 200, type: 'string'
                response 500, type: 'string'
              end
            end

            attr_reader :error

            def notice_error(error)
              @error = error
            end
          end
          controller.api_operation(status: 200) { raise 'foo' }
          error = controller.error

          assert_kind_of(RuntimeError, error)
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_calls_an_on_rescue_callback_as_a_block") do
          error = nil

          controller = dummy_controller do
            api_definitions do
              rescue_from RuntimeError, with: 500
              on_rescue { |e| error = e }

              operation do
                response 200, type: 'string'
                response 500, type: 'string'
              end
            end
          end
          controller.api_operation(status: 200) { raise 'foo' }

          assert_kind_of(RuntimeError, error)
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_reraises_an_error_when_the_response_does_not_exist") do
          controller = dummy_controller do
            api_definitions do
              rescue_from RuntimeError, with: 500

              operation do
                response 200, type: 'string'
              end
            end
          end
          error = assert_raises(RuntimeError) do
            controller.api_operation(status: 200) { raise 'foo' }
          end
          assert_equal('foo', error.message)
        end

        define_method("test_#{name}_on_other_type_than_json") do
          controller = dummy_controller do
            api_operation do
              response 200, type: 'string', content_type: 'text/plain'
            end
          end
          controller.send(method, status: 200) { 'foo' }
          response = controller.response

          assert_nil(response.status)
          assert_nil(response.content_type)
          assert_nil(response.body)
        end
      end

      def test_api_operation_on_strong_parameters
        controller_class = dummy_controller_class do
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
        controller_class = dummy_controller_class do
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

      # #api_params

      def test_api_params
        controller = dummy_controller do
          api_operation do
            parameter 'foo', type: 'string'
            response type: 'string'
          end
        end
        controller.params['foo'] = 'bar'
        assert_equal('bar', controller.api_params.foo)

        # Errors
        error = assert_raises(RuntimeError) do
          controller.api_params('foo')
        end
        assert_equal('operation not defined: foo', error.message)
      end

      def test_api_params_on_strong_parameters
        controller_class = dummy_controller_class do
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
        api_params = controller.api_params(strong: true)
        assert_predicate(api_params, :valid?)

        # Bad request
        controller = controller_class.new(params: { bar: 'foo' })

        api_params = controller.api_params(strong: true)
        assert_predicate(api_params, :invalid?)
        assert(api_params.errors.added?(:base, "'bar' isn't allowed"))
      end

      # #api_response

      def test_api_response
        controller = dummy_controller do
          api_operation do
            response 200, type: 'string'
          end
        end
        response = controller.api_response('foo', status: 200)
        assert_equal('"foo"', response.to_json)

        # Errors
        error = assert_raises(RuntimeError) do
          controller.api_response('foo', 'foo', status: 200)
        end
        assert_equal('operation not defined: foo', error.message)

        error = assert_raises(RuntimeError) do
          controller.api_response('foo', status: 204)
        end
        assert_equal('status code not defined: 204', error.message)
      end

      private

      def dummy_controller(&block)
        dummy_controller_class(&block).new
      end

      def dummy_controller_class(&block)
        klass = Class.new(ActionController::API) do
          include DSL
          include Methods
        end
        klass.class_eval(&block)
        klass
      end
    end
  end
end
