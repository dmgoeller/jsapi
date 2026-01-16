# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Methods
      module Callbacks
        class CallbackTest < Minitest::Test
          class DummyController
            def truthy?
              true
            end

            def falsely?
              false
            end
          end

          def test_skip_on
            callback = Callback.new(nil)

            %w[foo bar].each do |operation_name|
              assert(
                !callback.skip_on?(nil, operation_name),
                "Expected #{callback.inspect} not be skipped on " \
                "#{operation_name.inspect}."
              )
            end
          end

          def test_skip_on_with_except_option
            {
              [] => [],
              :foo => %w[foo],
              %i[foo bar] => %w[foo bar]
            }.each do |except, truthy_on|
              callback = Callback.new(nil, except: except)

              ['', 'foo', 'bar'].each do |operation_name|
                assert(
                  callback.skip_on?(nil, operation_name) ==
                    expected = truthy_on.include?(operation_name),
                  "Expected #{callback.inspect} #{expected ? '' : 'not'} " \
                  "to be skipped on #{operation_name.inspect}."
                )
              end
            end
          end

          def test_skip_on_with_only_option
            {
              [] => ['', 'foo', 'bar'],
              :foo => ['', 'bar'],
              %i[foo bar] => ['']
            }.each do |only, truthy_on|
              callback = Callback.new(nil, only: only)

              ['', 'foo', 'bar'].each do |operation_name|
                assert(
                  callback.skip_on?(nil, operation_name) ==
                    expected = truthy_on.include?(operation_name),
                  "Expected #{callback.inspect} #{expected ? '' : 'not '}" \
                  "to be skipped on #{operation_name.inspect}."
                )
              end
            end
          end

          def test_skip_on_with_if_option
            controller = DummyController.new

            # Truthy
            callback = Callback.new(nil, if: :truthy?)
            assert_not(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, if: -> { truthy? })
            assert_not(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, if: [:truthy?, -> { true }])
            assert_not(callback.skip_on?(controller, ''))

            # Falsely
            callback = Callback.new(nil, if: :falsely?)
            assert(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, if: -> { falsely? })
            assert(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, if: [:truthy?, -> { false }])
            assert(callback.skip_on?(controller, ''))
          end

          def test_skip_on_with_unless_option
            controller = DummyController.new

            # Truthy
            callback = Callback.new(nil, unless: :truthy?)
            assert(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, unless: -> { truthy? })
            assert(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, unless: [:truthy?, -> { true }])
            assert(callback.skip_on?(controller, ''))

            # Falsely
            callback = Callback.new(nil, unless: :falsely?)
            assert_not(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, unless: -> { falsely? })
            assert_not(callback.skip_on?(controller, ''))

            callback = Callback.new(nil, unless: [:truthy?, -> { false }])
            assert(callback.skip_on?(controller, ''))
          end

          # #inspect

          def test_inspect
            class_name = Callback.name
            assert_equal(
              "#<#{class_name} :foo>",
              Callback.new(:foo).inspect
            )
            assert_equal(
              "#<#{class_name} :foo, if: :bar?>",
              Callback.new(:foo, if: :bar?).inspect
            )
            assert_equal(
              "#<#{class_name} :foo, if: :bar?, only: \"baz\">",
              Callback.new(:foo, if: :bar?, only: 'baz').inspect
            )
            assert_equal(
              "#<#{class_name} :foo, if: :bar?, only: [\"baz\", \"bas\"]>",
              Callback.new(:foo, if: :bar?, only: %w[baz bas]).inspect
            )
          end
        end
      end
    end
  end
end
