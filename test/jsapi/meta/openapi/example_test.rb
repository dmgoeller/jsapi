# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module OpenAPI
      class ExampleTest < Minitest::Test
        def test_new_example
          example = Example.new(value: 'foo')
          assert_kind_of(Example::Model, example)
        end

        def test_new_reference
          example = Example.new(ref: 'foo')
          assert_kind_of(Example::Reference, example)
        end
      end
    end
  end
end
