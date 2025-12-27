# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Methods
      class CallbacksTest < Minitest::Test
        def test_before_processing_callbacks
          object = Class.new do
            include Callbacks

            api_before_processing :raise_foo, only: :foo
            api_before_processing :raise_bar, except: :baz

            def test_before_processing(operation_name)
              _api_before_processing(operation_name)
            end

            private

            %w[foo bar].each do |name|
              define_method(:"raise_#{name}") { raise name }
            end
          end.new

          %w[foo bar].each do |name|
            error = assert_raises(StandardError) do
              object.test_before_processing(name)
            end
            assert_equal(name, error.message)
          end

          assert_nil(object.test_before_processing('baz'))
        end

        def test_before_processing_callbacks_with_blocks
          object = Class.new do
            include Callbacks

            api_before_processing(only: :foo) { raise 'foo' }

            api_before_processing(except: :baz) { raise 'bar' }

            def test_before_processing(operation_name)
              _api_before_processing(operation_name)
            end
          end.new

          %w[foo bar].each do |name|
            error = assert_raises(StandardError) do
              object.test_before_processing(name)
            end
            assert_equal(name, error.message)
          end

          assert_nil(object.test_before_processing('baz'))
        end

        def test_before_rendering_callbacks
          object = Class.new do
            include Callbacks

            api_before_rendering :append_foo, only: :foo
            api_before_rendering :append_bar, except: :baz

            def test_before_rendering(operation_name)
              _api_before_rendering(operation_name, 'result')
            end

            private

            %w[foo bar].each do |name|
              define_method(:"append_#{name}") { |result| "#{result} #{name}" }
            end
          end.new
          {
            'foo' => 'result foo bar',
            'bar' => 'result bar',
            'baz' => 'result'
          }.each do |operation_name, expected|
            assert(
              expected == actual = object.test_before_rendering(operation_name),
              "Expected result for #{operation_name.inspect} to be " \
              "#{expected.inspect}, is: #{actual.inspect}."
            )
          end
        end

        def test_before_rendering_callbacks_with_blocks
          object = Class.new do
            include Callbacks

            api_before_rendering(only: :foo) { |result| "#{result} foo" }

            api_before_rendering(except: :baz) { |result| "#{result} bar" }

            def test_before_rendering(operation_name)
              _api_before_rendering(operation_name, 'result')
            end
          end.new
          {
            'foo' => 'result foo bar',
            'bar' => 'result bar',
            'baz' => 'result'
          }.each do |operation_name, expected|
            assert(
              expected == actual = object.test_before_rendering(operation_name),
              "Expected result for #{operation_name.inspect} to be " \
              "#{expected.inspect}, is: #{actual.inspect}."
            )
          end
        end
      end
    end
  end
end
