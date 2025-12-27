# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class ArrayWrapperTest < Minitest::Test
        def test_items
          items = Array::Wrapper.new(
            array = Array.new(
              items: {}
            ),
            Definitions.new
          ).items

          assert_kind_of(Schema::Wrapper, items)
          assert_equal(array.items, items.__getobj__)
        end
      end
    end
  end
end
