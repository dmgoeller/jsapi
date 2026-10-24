# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    module Schema
      class AdditionalPropertiesTest < Minitest::Test
        def test_schema
          additional_properties = AdditionalProperties.new(type: 'string')
          assert_kind_of(String, additional_properties.schema)
        end

        def test_schema_reference
          additional_properties = AdditionalProperties.new(ref: 'foo')
          assert_kind_of(Reference, additional_properties.schema)
          assert_equal('foo', additional_properties.schema.ref)
        end
      end
    end
  end
end
