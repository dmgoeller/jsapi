# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Callable
      class SymbolEvaluatorTest < Minitest::Test
        def test_call_on_nil
          evaluator = SymbolEvaluator.new(:foo)

          assert_nil(evaluator.call(nil))
        end

        def test_call_on_object
          evaluator = SymbolEvaluator.new(:foo)

          object = Class.new do
            def foo
              'bar'
            end
          end.new
          assert_equal('bar', evaluator.call(object))
        end

        def test_call_on_hash
          evaluator = SymbolEvaluator.new(:foo)

          [:foo, 'foo'].each do |key|
            assert_equal('bar', evaluator.call({ key => 'bar' }))
          end
        end

        # Inspection

        def test_inspect
          assert_equal(
            '#<Jsapi::Meta::Callable::SymbolEvaluator :foo>',
            SymbolEvaluator.new(:foo).inspect
          )
        end
      end
    end
  end
end
