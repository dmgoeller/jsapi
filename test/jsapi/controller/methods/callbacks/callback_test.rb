# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Methods
      module Callbacks
        class CallbackTest < Minitest::Test
          def test_skip_on
            callback = Callback.new(nil)

            %w[foo bar].each do |operation_name|
              assert(
                !callback.skip_on?(operation_name),
                "Expected #{callback.inspect} not be skipped on #{operation_name.inspect}."
              )
            end
          end

          def test_skip_on_except
            {
              [] => [],
              :foo => %w[foo],
              %i[foo bar] => %w[foo bar]
            }.each do |except, truthy_on|
              callback = Callback.new(nil, except: except)

              ['', 'foo', 'bar'].each do |operation_name|
                assert(
                  callback.skip_on?(operation_name) ==
                    expected = truthy_on.include?(operation_name),
                  "Expected #{callback.inspect} #{expected ? '' : 'not'} " \
                  "to be skipped on #{operation_name.inspect}."
                )
              end
            end
          end

          def test_skip_on_only
            {
              [] => ['', 'foo', 'bar'],
              :foo => ['', 'bar'],
              %i[foo bar] => ['']
            }.each do |only, truthy_on|
              callback = Callback.new(nil, only: only)

              ['', 'foo', 'bar'].each do |operation_name|
                assert(
                  callback.skip_on?(operation_name) ==
                    expected = truthy_on.include?(operation_name),
                  "Expected #{callback.inspect} #{expected ? '' : 'not'} " \
                  "to be skipped on #{operation_name.inspect}."
                )
              end
            end
          end
        end
      end
    end
  end
end
