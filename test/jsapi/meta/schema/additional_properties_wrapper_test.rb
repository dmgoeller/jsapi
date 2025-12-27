# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class AdditionalPropertiesWrapperTest < Minitest::Test
        def test_schema
          schema = AdditionalProperties::Wrapper.new(
            additional_properties = AdditionalProperties.new,
            Definitions.new
          ).schema

          assert_kind_of(Schema::Wrapper, schema)
          assert_equal(additional_properties.schema, schema.__getobj__)
        end
      end
    end
  end
end
