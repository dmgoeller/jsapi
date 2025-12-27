# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Controller
    class ActionsTest < Minitest::Test
      include TestHelper

      %i[api_action api_action!].each do |method|
        define_method(:"test_#{method}") do
          controller = controller(params: { p: 'q' }) do
            api_operation 'foo' do
              parameter 'p', type: 'string'
              response type: 'string'
            end
            send(method, :foo)

            def foo(api_params)
              "value of p is #{api_params.p}"
            end
          end
          controller.index
          assert_equal('"value of p is q"', controller.response.body)
        end

        define_method(:"test_#{method}_with_operation_name") do
          controller = controller(params: { p: 'q' }) do
            api_operation 'foo' do
              parameter 'p', type: 'string'
              response type: 'string'
            end
            send(method, :bar, 'foo')

            def bar(api_params)
              "value of p is #{api_params.p}"
            end
          end
          controller.index
          assert_equal('"value of p is q"', controller.response.body)
        end

        define_method(:"test_#{method}_with_block_only") do
          controller = controller(params: { p: 'q' }) do
            api_operation 'foo' do
              parameter 'p', type: 'string'
              response type: 'string'
            end
            send(method) do |api_params|
              "value of p is #{api_params.p}"
            end
          end
          controller.index
          assert_equal('"value of p is q"', controller.response.body)
        end

        define_method(:"test_#{method}_with_operation_name_and_block") do
          controller = controller(params: { p: 'q' }) do
            api_operation 'foo' do
              parameter 'p', type: 'string'
              response type: 'string'
            end
            send(method, 'foo') do |api_params|
              "value of p is #{api_params.p}"
            end
          end
          controller.index
          assert_equal('"value of p is q"', controller.response.body)
        end

        define_method(:"test_#{method}_raises_an_error_when_neither_name_nor_block_is_given") do
          error = assert_raises(ArgumentError) do
            controller { send(method) }
          end
          assert_equal('neither name nor block is given', error.message)
        end
      end
    end
  end
end
