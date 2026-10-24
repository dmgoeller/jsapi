# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class ParameterTest < Minitest::Test
      def test_new
        parameter = Parameter.new('foo', type: 'string')
        assert_kind_of(Parameter::Base, parameter)
      end

      def test_new_reference
        parameter = Parameter.new('foo', ref: 'foo')
        assert_kind_of(Parameter::Reference, parameter)
      end
    end
  end
end
