# frozen_string_literal: true

module Jsapi
  module DSL
    class ParameterTest < Minitest::Test
      # #example

      def test_example
        parameter = Definition::Parameter.new('param')
        Parameter.new(parameter) { example 'foo' }

        assert_equal('foo', parameter.example('default').value)
      end
    end
  end
end
