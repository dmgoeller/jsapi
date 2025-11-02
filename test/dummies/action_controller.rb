# frozen_string_literal: true

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
    attr_reader :params, :request

    def initialize(params: {}, request_headers: {})
      @params = ActionController::Parameters.new(params)
      @request = ActionDispatch::Request.new(headers: request_headers)
    end

    def content_type=(content_type)
      response.content_type = content_type
    end

    def head(*args)
      response.status = args.first
      true
    end

    def render(**options)
      response.status = options[:status]
      response.body = options[:json]&.to_json
    end

    def response
      @response ||= ActionDispatch::Response.new
    end
  end
end
