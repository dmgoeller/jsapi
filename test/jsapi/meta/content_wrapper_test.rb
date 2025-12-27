# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ContentWrapperTest < Minitest::Test
      def test_schema
        schema = Content::Wrapper.new(
          content = Content.new,
          Definitions.new
        ).schema

        assert_kind_of(Schema::Wrapper, schema)
        assert_equal(content.schema, schema.__getobj__)
      end
    end
  end
end
