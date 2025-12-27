# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class PropertyWrapperTest < Minitest::Test
      def test_schema
        schema = Property::Wrapper.new(
          property = Property.new('foo'),
          Definitions.new
        ).schema

        assert_kind_of(Schema::Wrapper, schema)
        assert_equal(property.schema, schema.__getobj__)
      end
    end
  end
end
