# frozen_string_literal: true

require_relative 'abstract_controller'

module ActionController
  module Live; end

  class Parameters < ActiveSupport::HashWithIndifferentAccess
    def permit!
      self
    end

    def permit(*filters)
      slice(*filters)
    end
  end

  class API
    attr_reader :params, :request, :response

    def initialize(params: {}, request_headers: {})
      @params = ActionController::Parameters.new(params)
      @request = ActionDispatch::Request.new(headers: request_headers)
      @response = ActionDispatch::Response.new
    end

    def content_type=(content_type)
      response.content_type = content_type
    end

    def head(*args)
      response.status = args.first
      true
    end

    def render(**options)
      raise AbstractController::DoubleRenderError if response_body

      response_body, content_type =
        if options.key?(:json)
          [options[:json]&.to_json, 'application/json']
        elsif options.key?(:plain)
          [options[:plain].to_s, 'text/plain']
        else
          ['', 'text/plain']
        end
      response.status = options[:status]
      response.content_type = options[:content_type] || content_type
      response.body = response_body
    end

    def response_body
      response.body
    end
  end
end
