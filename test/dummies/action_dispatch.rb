# frozen_string_literal: true

module ActionDispatch
  class Request
    attr_reader :headers, :query_parameters

    def initialize(headers: {}, query_parameters: {})
      @headers = headers
      @query_parameters = query_parameters
    end
  end

  class Response
    attr_accessor :content_type, :status
    attr_writer :body

    def body
      return @body if defined? @body

      @stream.string if defined? @stream
    end

    def stream
      @stream ||= StringIO.new
    end
  end
end
