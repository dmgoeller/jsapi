# frozen_string_literal: true

module Jsapi
  module DSL
    class PropertyTest < Minitest::Test
      def test_description
        property_model = Model::Property.new('property', type: 'string')
        Property.new(property_model).call { description 'Foo' }
        assert_equal('Foo', property_model.schema.description)
      end

      def test_example
        property_model = Model::Property.new('property', type: 'string')
        Property.new(property_model).call { example 'foo' }
        assert_equal(%w[foo], property_model.schema.examples)
      end

      def test_deprecated
        property_model = Model::Property.new('property')
        Property.new(property_model).call { deprecated true }
        assert(property_model.deprecated?)
      end

      def test_delegates_to_schema
        property_model = Model::Property.new('property', type: 'string')
        Property.new(property_model).call { format 'date' }
        assert_equal('date', property_model.schema.format)
      end
    end
  end
end
