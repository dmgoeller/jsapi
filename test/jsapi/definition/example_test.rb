# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class ExampleTest < Minitest::Test
      def test_new
        example = Example.new(value: 'foo')
        assert_kind_of(Example::Base, example)
      end

      def test_new_reference
        example = Example.new(ref: 'foo')
        assert_kind_of(Example::Reference, example)
      end
    end
  end
end
