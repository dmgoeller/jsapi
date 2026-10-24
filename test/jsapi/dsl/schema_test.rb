# frozen_string_literal: true

module Jsapi
  module DSL
    class SchemaTest < Minitest::Test
      # #all_of

      def test_all_of
        all_of_references = schema do
          all_of 'foo'
        end.all_of_references

        assert_equal(%w[foo], all_of_references.map(&:ref))
      end

      # #example

      def test_example
        examples = schema do
          example 'foo'
        end.examples

        assert_equal(%w[foo], examples)
      end

      # #format

      def test_format
        format = schema(type: 'string') do
          format 'date'
        end.format

        assert_equal('date', format)
      end

      # #items

      def test_items
        items = schema(type: 'array') do
          items description: 'Lorem ipsum'
        end.items

        assert_predicate(items, :present?)
        assert_equal('Lorem ipsum', items.description)
      end

      def test_items_with_block
        items = schema(type: 'array') do
          items do
            description 'Lorem ipsum'
          end
        end.items

        assert_predicate(items, :present?)
        assert_equal('Lorem ipsum', items.description)
      end

      def test_items_raises_an_error_when_type_is_other_than_array
        error = assert_raises Error do
          schema(type: 'object') { items type: 'string' }
        end
        assert_equal("items isn't supported for 'object'", error.message)
      end

      # #model

      def test_model
        klass = Class.new(Model::Base)
        model = schema(type: 'object') do
          model klass
        end.model

        assert_equal(klass, model)
      end

      def test_model_with_block
        model = schema(type: 'object') do
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
        model = schema(type: 'object') do
          model klass do
            def foo
              'bar'
            end
          end
        end.model.new({})

        assert_kind_of(klass, model)
        assert_equal('bar', model.foo)
      end

      def test_model_raises_an_error_when_type_is_other_than_object
        error = assert_raises Error do
          schema(type: 'array') { model {} }
        end
        assert_equal("model isn't supported for 'array'", error.message)
      end

      # #property

      def test_property
        property = schema(type: 'object') do
          property 'foo', description: 'Lorem ipsum'
        end.property('foo')

        assert_predicate(property, :present?)
        assert_equal('Lorem ipsum', property.description)
      end

      def test_property_with_block
        property = schema(type: 'object') do
          property 'foo' do
            description 'Lorem ipsum'
          end
        end.property('foo')

        assert_predicate(property, :present?)
        assert_equal('Lorem ipsum', property.description)
      end

      def test_property_raises_an_error_when_type_is_other_than_object
        error = assert_raises Error do
          schema(type: 'array') { property 'foo' }
        end
        assert_equal(
          "property isn't supported for 'array' (at property \"foo\")",
          error.message
        )
      end

      private

      def schema(**keywords, &block)
        Definition::Schema.new(keywords).tap do |schema|
          Schema.new(schema, &block)
        end
      end
    end
  end
end
