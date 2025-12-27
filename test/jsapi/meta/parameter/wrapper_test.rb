# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Parameter
      class WrapperTest < Minitest::Test
        def test_schema
          schema = Wrapper.new(
            parameter = Base.new('foo'),
            Definitions.new
          ).schema

          assert_kind_of(Schema::Wrapper, schema)
          assert_equal(parameter.schema, schema.__getobj__)
        end
      end
    end
  end
end
