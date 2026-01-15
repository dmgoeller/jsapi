# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Methods
      module Callbacks
        class ClassMethodsTest < Minitest::Test
          %i[after_validation before_rendering].each do |kind|
            method = :"api_#{kind}"

            define_method(:"test_api_#{kind}") do
              classes = {
                base: base = Class.new do
                  extend ClassMethods
                  send(method, :foo)
                end,
                subclass: Class.new(base) do
                  send(method, :bar)
                end
              }
              { base: %i[foo], subclass: %i[foo bar] }.each do |key, expected|
                callbacks = classes[key]._api_callbacks(kind)
                assert(
                  expected == actual = callbacks.map(&:method_or_proc),
                  "Expected #{kind} callbacks of #{name} to be  " \
                  "#{expected.inspect}, is: #{actual}."
                )
              end
            end

            define_method("test_api_#{kind}_raises_an_error_when_neither_" \
                          'a_method_nor_a_block_is_specified') do
              error = assert_raises(ArgumentError) do
                Class.new do
                  extend ClassMethods
                  send(method)
                end
              end
              assert_equal('either a method or a block must be specified', error.message)
            end
          end
        end
      end
    end
  end
end
