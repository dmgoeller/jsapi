# frozen_string_literal: true

module Jsapi
  module Controller
    # The base API controller class.
    #
    # A minimal API controller responding with "Hello world" looks like:
    #
    #   class FooController < Jsapi::Controller::Base
    #     api_operation do
    #       response type: 'string'
    #     end
    #
    #     api_action { 'Hello world' }
    #
    class Base < ActionController::API
      include Actions
      include DSL
      include Methods
    end
  end
end
