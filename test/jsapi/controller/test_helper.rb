# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module TestHelper
      private

      def controller(params: {}, request_headers: {}, &block)
        controller_class(&block).new(
          params: params,
          request_headers: request_headers
        )
      end

      def controller_class(&block)
        klass = Class.new(ActionController::API) do
          include Actions
          include DSL
          include Methods
        end
        klass.class_eval(&block) if block
        klass
      end
    end
  end
end
