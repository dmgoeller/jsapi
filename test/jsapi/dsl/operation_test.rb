# frozen_string_literal: true

module Jsapi
  module DSL
    class OperationTest < Minitest::Test
      # #callback

      def test_callback
        callback = operation do
          callback 'foo', expressions: {
            '{$url}' => {
              operations: {
                'get' => { description: 'Lorem ipsum' }
              }
            }
          }
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal(
          'Lorem ipsum',
          callback.expression('{$url}')&.operation('get')&.description
        )
      end

      def test_callback_with_block
        callback = operation do
          callback 'foo' do
            expression '{$url}' do
              operation 'get', description: 'Lorem ipsum'
            end
          end
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal(
          'Lorem ipsum',
          callback.expression('{$url}')&.operation('get')&.description
        )
      end

      def test_callback_reference
        callback = operation do
          callback ref: 'foo'
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal('foo', callback.ref)
      end

      def test_callback_reference_by_name
        callback = operation do
          callback 'foo'
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal('foo', callback.ref)
      end

      # #method

      def test_method
        method = operation do
          method 'post'
        end.method

        assert_equal('post', method)
      end

      # #model

      def test_model
        klass = Class.new(Model::Base)
        model = operation do
          model klass
        end.model

        assert_equal(klass, model)
      end

      def test_model_with_block
        model = operation do
          model do
            def foo
              'bar'
            end
          end
        end.model.new({})

        assert_kind_of(Model::Base, model)
        assert_equal('bar', model.foo)
      end

      def test_model_with_class_and_block
        klass = Class.new(Model::Base)
        model = operation do
          model klass do
            def foo
              'bar'
            end
          end
        end.model.new({})

        assert_kind_of(klass, model)
        assert_equal('bar', model.foo)
      end

      # #parameter

      def test_parameter
        parameter = operation do
          parameter 'foo', description: 'Lorem ipsum'
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_with_block
        parameter = operation do
          parameter 'foo' do
            description 'Lorem ipsum'
          end
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_reference
        parameter = operation do
          parameter ref: 'foo'
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('foo', parameter.ref)
      end

      def test_parameter_reference_by_name
        parameter = operation do
          parameter 'foo'
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('foo', parameter.ref)
      end

      # #request_body

      def test_request_body
        request_body = operation do
          request_body description: 'Lorem ipsum'
        end.request_body

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_with_block
        request_body = operation do
          request_body do
            description 'Lorem ipsum'
          end
        end.request_body

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_reference
        request_body = operation do
          request_body ref: 'foo'
        end.request_body

        assert_predicate(request_body, :present?)
        assert_equal('foo', request_body.ref)
      end

      def test_request_body_reference_by_name
        request_body = operation do
          request_body 'foo'
        end.request_body

        assert_predicate(request_body, :present?)
        assert_equal('foo', request_body.ref)
      end

      def test_request_body_raises_an_error_if_name_and_keywords_are_specified_together
        error = assert_raises(Error) do
          operation do
            request_body 'foo', type: 'object'
          end
        end
        assert_equal(
          "name can't be specified together with keywords or a block (at request body)",
          error.message
        )
      end

      # #response

      def test_response
        response = operation do
          response 200, description: 'Lorem ipsum'
        end.response(200)

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_with_block
        response = operation do
          response do
            description 'Lorem ipsum'
          end
        end.response('default')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_reference
        response = operation do
          response 200, ref: 'foo'
        end.response(200)

        assert_predicate(response, :present?)
        assert_equal('foo', response.ref)
      end

      def test_response_reference_by_name
        response = operation do
          response 200, 'foo'
        end.response(200)

        assert_predicate(response, :present?)
        assert_equal('foo', response.ref)
      end

      def test_default_response
        response = operation do
          response description: 'Lorem ipsum'
        end.response('default')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_default_response_with_block
        response = operation do
          response 200 do
            description 'Lorem ipsum'
          end
        end.response(200)

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_default_response_as_reference
        response = operation do
          response ref: 'foo'
        end.response('default')

        assert_predicate(response, :present?)
        assert_equal('foo', response.ref)
      end

      def test_default_response_as_reference_by_name
        response = operation do
          response 'foo'
        end.response('default')

        assert_predicate(response, :present?)
        assert_equal('foo', response.ref)
      end

      def test_response_raises_an_error_if_name_and_keywords_are_specified_together
        error = assert_raises(Error) do
          operation do
            response 200, 'foo', type: 'object'
          end
        end
        assert_equal(
          "name can't be specified together with keywords or a block (at response 200)",
          error.message
        )
      end

      private

      def operation(**keywords, &block)
        Meta::Operation.new(keywords).tap do |operation|
          Operation.new(operation, &block)
        end
      end
    end
  end
end
