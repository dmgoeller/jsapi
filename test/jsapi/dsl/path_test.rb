# frozen_string_literal: true

module Jsapi
  module DSL
    class PathTest < Minitest::Test
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

      private

      def definitions(&block)
        Meta::Definitions.new.tap do |definitions|
          Definitions.new(definitions, &block)
        end
      end
    end
  end
end
