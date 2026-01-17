# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Controller
    module Methods
      class CallbacksTest < Minitest::Test
        include TestHelper

        def test_after_validation_callbacks
          controller_class = controller_class do
            include Callbacks

            api_after_validation :foo, only: :foo
            api_after_validation :bar, except: :baz

            def test_after_validation(operation_name)
              _api_callback(:after_validation, operation_name, 'params')
            end

            private

            # Callback with arguments
            def foo(operation_name, api_params)
              checks << "foo(#{operation_name.inspect}, #{api_params.inspect})"
            end

            # Callback without arguments
            def bar
              checks << 'bar'
            end
          end

          {
            'foo' => ['foo("foo", "params")', 'bar'],
            'bar' => %w[bar],
            'baz' => []
          }.each do |operation_name, expected|
            controller = controller_class.new
            controller.test_after_validation(operation_name)

            assert(
              controller.checks == expected,
              "Expected all of #{expected.inspect} " \
              "to be called on #{operation_name.inspect}, " \
              "was: #{controller.checks.inspect}."
            )
          end
        end

        def test_after_validation_callbacks_with_blocks
          controller_class = controller_class do
            include Callbacks

            # Callback with arguments
            api_after_validation only: :foo do |operation_name, api_params|
              checks << "foo(#{operation_name.inspect}, #{api_params.inspect})"
            end

            # Callback without arguments
            api_after_validation except: :baz do
              checks << 'bar'
            end

            def test_after_validation(operation_name)
              _api_callback(:after_validation, operation_name, 'params')
            end
          end

          {
            'foo' => ['foo("foo", "params")', 'bar'],
            'bar' => %w[bar],
            'baz' => []
          }.each do |operation_name, expected|
            controller = controller_class.new
            controller.test_after_validation(operation_name)

            assert(
              controller.checks == expected,
              "Expected all of #{expected.inspect} " \
              "to be called on #{operation_name.inspect}, " \
              "was: #{controller.checks.inspect}."
            )
          end
        end

        def test_before_rendering_callbacks
          controller_class = controller_class do
            include Callbacks

            api_before_rendering :append_foo, only: :foo
            api_before_rendering :append_bar, except: :baz

            def test_before_rendering(operation_name)
              _api_before_rendering(operation_name, 'result', 'params')
            end

            private

            # Callback with additional arguments
            def append_foo(result, operation_name, api_params)
              "#{result} foo(#{operation_name.inspect}, #{api_params.inspect})"
            end

            # Callback without additional arguments
            def append_bar(result)
              "#{result} bar"
            end
          end

          {
            'foo' => 'result foo("foo", "params") bar',
            'bar' => 'result bar',
            'baz' => 'result'
          }.each do |operation_name, expected|
            actual = controller_class.new.test_before_rendering(operation_name)
            assert(
              expected == actual,
              "Expected result for #{operation_name.inspect} to be " \
              "#{expected.inspect}, is: #{actual.inspect}."
            )
          end
        end

        def test_before_rendering_callbacks_with_blocks
          controller_class = controller_class do
            include Callbacks

            # Callback with additional arguments
            api_before_rendering only: :foo do |result, operation_name, api_params|
              "#{result} foo(#{operation_name.inspect}, #{api_params.inspect})"
            end

            # Callback without additional arguments
            api_before_rendering except: :baz do |result|
              "#{result} bar"
            end

            def test_before_rendering(operation_name)
              _api_before_rendering(operation_name, 'result', 'params')
            end
          end

          {
            'foo' => 'result foo("foo", "params") bar',
            'bar' => 'result bar',
            'baz' => 'result'
          }.each do |operation_name, expected|
            actual = controller_class.new.test_before_rendering(operation_name)
            assert(
              expected == actual,
              "Expected result for #{operation_name.inspect} to be " \
              "#{expected.inspect}, is: #{actual.inspect}."
            )
          end
        end
      end
    end
  end
end
