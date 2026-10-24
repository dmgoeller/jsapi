# frozen_string_literal: true

module Jsapi
  module DSL
    class ExamplesTest < Minitest::Test
      class Dummy < Base
        include Examples
      end

      def test_example
        example = examples do
          example 'bar'
        end['default']

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_with_keywords
        example = examples do
          example value: 'bar'
        end['default']

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_with_block
        example = examples do
          example do
            value 'bar'
          end
        end['default']

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_with_name_and_keywords
        example = examples do
          example 'foo', value: 'bar'
        end['foo']

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_with_name_and_block
        example = examples do
          example 'foo' do
            value 'bar'
          end
        end['foo']

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      private

      def examples(&block)
        Definition::Parameter.new('foo').tap do |model|
          Class.new(Base) do
            include Examples
          end.new(model, &block)
        end.examples
      end
    end
  end
end
