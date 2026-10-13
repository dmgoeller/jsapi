# frozen_string_literal: true

module Jsapi
  module DSL
    class PathTest < Minitest::Test
      # #model

      def test_model
        klass = Class.new(Model::Base)
        model = definitions do
          path 'foo' do
            model klass
          end
        end.path('foo')&.model

        assert_equal(klass, model)
      end

      def test_model_with_block
        model = definitions do
          path 'foo' do
            model do
              def foo
                'bar'
              end
            end
          end
        end.path('foo').model.new({})

        assert_kind_of(Model::Base, model)
        assert_equal('bar', model.foo)
      end

      def test_model_with_class_and_block
        klass = Class.new(Model::Base)
        model = definitions do
          path 'foo' do
            model klass do
              def foo
                'bar'
              end
            end
          end
        end.path('foo').model.new({})

        assert_kind_of(klass, model)
        assert_equal('bar', model.foo)
      end

      # #operation

      def test_named_operation
        operation = definitions do
          path 'foo' do
            operation 'bar'
          end
        end.find_operation('bar')

        assert_predicate(operation, :present?)
        assert_equal('/foo', operation.full_path.to_s)
      end

      def test_named_operation_with_path
        operation = definitions do
          path 'foo' do
            operation 'bar', path: 'bar'
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_equal('/foo/bar', operation.full_path.to_s)
      end

      def test_named_operation_with_block
        operation = definitions do
          path 'foo' do
            operation 'bar' do
              path 'bar'
            end
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_equal('/foo/bar', operation.full_path.to_s)
      end

      def test_nameless_operation
        operation = definitions do
          path 'foo' do
            operation()
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_nil(operation.name)
        assert_equal('/foo', operation.full_path.to_s)
      end

      def test_nameless_operation_with_path
        operation = definitions do
          path 'foo' do
            operation path: 'bar'
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_nil(operation.name)
        assert_equal('/foo/bar', operation.full_path.to_s)
      end

      def test_nameless_operation_with_block
        operation = definitions do
          path 'foo' do
            operation do
              path 'bar'
            end
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_nil(operation.name)
        assert_equal('/foo/bar', operation.full_path.to_s)
      end

      # #parameter

      def test_parameter
        parameter = definitions do
          path 'foo' do
            parameter 'bar', description: 'Lorem ipsum'
          end
        end.path('foo')&.parameter('bar')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_with_block
        parameter = definitions do
          path 'foo' do
            parameter 'bar' do
              description 'Lorem ipsum'
            end
          end
        end.path('foo')&.parameter('bar')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_reference
        parameter = definitions do
          path 'foo' do
            parameter ref: 'bar'
          end
        end.path('foo')&.parameter('bar')

        assert_predicate(parameter, :present?)
        assert_equal('bar', parameter.ref)
      end

      def test_parameter_reference_by_name
        parameter = definitions do
          path 'foo' do
            parameter 'bar'
          end
        end.path('foo')&.parameter('bar')

        assert_predicate(parameter, :present?)
        assert_equal('bar', parameter.ref)
      end

      # #path

      def test_nested_path
        paths = definitions do
          path 'foo' do
            path 'bar'
          end
        end.paths

        assert_equal(%w[/foo /foo/bar], paths.keys.map(&:to_s).sort)
      end

      def test_nested_path_with_block
        operation = definitions do
          path 'foo' do
            path 'bar' do
              operation 'foo_bar'
            end
          end
        end.find_operation('foo_bar')

        assert_predicate(operation, :present?)
        assert_equal(Meta::Pathname.new('/foo/bar'), operation.full_path)
      end

      def test_empty_path_segment
        paths = definitions do
          path 'foo' do
            path do
              path 'bar'
            end
          end
        end.paths

        assert_equal(%w[/foo /foo/ /foo//bar], paths.keys.map(&:to_s).sort)
      end

      def test_root_and_empty_path_segment
        paths = definitions do
          path do
            path
          end
        end.paths

        assert_equal(%w[/ //], paths.keys.map(&:to_s).sort)
      end

      # #request_body

      def test_request_body
        request_body = definitions do
          path 'foo' do
            request_body description: 'Lorem ipsum'
          end
        end.path('foo').request_body

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_with_block
        request_body = definitions do
          path 'foo' do
            request_body do
              description 'Lorem ipsum'
            end
          end
        end.path('foo').request_body

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_reference
        request_body = definitions do
          path 'foo' do
            request_body ref: 'foo'
          end
        end.path('foo').request_body

        assert_predicate(request_body, :present?)
        assert_equal('foo', request_body.ref)
      end

      # #response

      def test_response
        response = definitions do
          path 'foo' do
            response 200, description: 'Lorem ipsum'
          end
        end.path('foo')&.response(200)

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_with_block
        response = definitions do
          path 'foo' do
            response 200 do
              description 'Lorem ipsum'
            end
          end
        end.path('foo')&.response(200)

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_reference
        response = definitions do
          path 'foo' do
            response 200, ref: 'bar'
          end
        end.path('foo')&.response(200)

        assert_predicate(response, :present?)
        assert_equal('bar', response.ref)
      end

      def test_response_reference_by_name
        response = definitions do
          path 'foo' do
            response 200, 'bar'
          end
        end.path('foo')&.response(200)

        assert_predicate(response, :present?)
        assert_equal('bar', response.ref)
      end

      def test_default_response
        response = definitions do
          path 'foo' do
            response description: 'Lorem ipsum'
          end
        end.path('foo')&.response('default')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_default_response_with_block
        response = definitions do
          path 'foo' do
            response do
              description 'Lorem ipsum'
            end
          end
        end.path('foo')&.response('default')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_default_response_as_reference
        response = definitions do
          path 'foo' do
            response ref: 'bar'
          end
        end.path('foo')&.response('default')

        assert_predicate(response, :present?)
        assert_equal('bar', response.ref)
      end

      def test_default_response_as_reference_by_name
        response = definitions do
          path 'foo' do
            response 'bar'
          end
        end.path('foo')&.response('default')

        assert_predicate(response, :present?)
        assert_equal('bar', response.ref)
      end

      def test_response_raises_an_error_when_name_and_keywords_are_specified_together
        error = assert_raises(Error) do
          definitions do
            path 'foo' do
              response 200, 'bar', description: 'Lorem ipsum'
            end
          end
        end
        assert_equal(
          "name can't be specified together with keywords or a block " \
          '(at path "foo" / response 200)',
          error.message
        )
      end

      private

      def definitions(&block)
        Meta::Definitions.new.tap do |definitions|
          Definitions.new(definitions, &block)
        end
      end
    end
  end
end
