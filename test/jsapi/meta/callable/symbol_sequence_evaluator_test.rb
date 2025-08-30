# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Callable
      class SymbolSequenceEvaluatorTest < Minitest::Test
        def test_call
          evaluator = SymbolSequenceEvaluator.new(:foo, :bar)

          assert_nil(evaluator.call(nil))

          nested = Struct.new(:bar).new('foo')
          object = Struct.new(:foo).new(nested)
          assert_equal('foo', evaluator.call(object))

          hash = { foo: { bar: 'foo' } }
          assert_equal('foo', evaluator.call(hash))

          hash = { foo: nested }
          assert_equal('foo', evaluator.call(hash))
        end

        # Inspection

        def test_inspect
          assert_equal(
            '#<Jsapi::Meta::Callable::SymbolSequenceEvaluator [:foo, :bar]>',
            SymbolSequenceEvaluator.new(:foo, :bar).inspect
          )
        end
      end
    end
  end
end
