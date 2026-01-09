# frozen_string_literal: true

module ActionDispatch
  class Request
    attr_reader :headers, :media_type, :query_parameters

    def initialize(headers: {}, query_parameters: {})
      @headers = headers
      @media_type = headers['Content-Type']
      @query_parameters = query_parameters
    end

    def authorization
      headers['Authorization']
    end
  end

  class Response
    attr_accessor :content_type
    attr_reader :status
    attr_writer :body

    def body
      return @body if defined? @body

      @stream.string if defined? @stream
    end

    def status=(status)
      @status =
        if status.is_a?(Symbol)
          Jsapi::Status::Code.status_code(status)
        else
          status&.to_i
        end || 200
    end

    def stream
      @stream ||= StringIO.new
    end
  end
end
