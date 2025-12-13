# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Methods
      module Callbacks
        class ClassMethodsTest < Minitest::Test
          %i[before_processing before_rendering].each do |kind|
            method = :"api_#{kind}"

            define_method(:"test_api_#{kind}") do
              callbacks = Class.new do
                extend ClassMethods
                send(method, :foo)
              end._api_callbacks(kind)

              assert_predicate(callbacks, :one?)
              assert_equal(:foo, callbacks.first.method_or_proc)
            end

            define_method("test_api_#{kind}_raises_an_error_when_neither_" \
                          'method_nor_block_is_given') do
              error = assert_raises(ArgumentError) do
                Class.new do
                  extend ClassMethods
                  send(method)
                end
              end
              assert_equal('neither method nor block is given', error.message)
            end
          end

          def test_inheritance
            classes = {
              base: base = Class.new do
                extend ClassMethods
                api_before_processing :foo
              end,
              subclass: Class.new(base) do
                api_before_processing :bar
              end
            }
            { base: %i[foo], subclass: %i[foo bar] }.each do |key, expected|
              callbacks = classes[key]._api_callbacks(:before_processing)
              assert(
                expected == actual = callbacks.map(&:method_or_proc),
                "Expected callbacks of #{name} to be #{expected.inspect}, is: #{actual}."
              )
            end
          end
        end
      end
    end
  end
end
