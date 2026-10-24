# frozen_string_literal: true

require 'net/http'
require 'uri'

module Jsapi
  module Client
    # Base class for response errors.
    class ResponseError < StandardError; end

    # Raised when the response body is invalid.
    class InvalidResponseBodyError < ResponseError

      # The Response::Body that caused the error.
      attr_reader :response_body

      def initialize(response_body) # :nodoc:
        super(Support::Messages.join(*response_body.errors.full_messages))
        @response_body = response_body
      end
    end

    # Raised when no response specification matches the status code returned by the server.
    class UnexpectedResponseError < ResponseError
      def initialize(operation, code) # :nodoc:
        super("Unexpected status code #{code} for operation #{operation.name.inspect}")
      end
    end

    # \Base client class.
    class Base
      include DSL
      include Exceptions

      ##
      # :attr: logger
      attr_accessor :logger

      ##
      # :attr_reader: request_headers
      # The Request::Headers set for every subsequent call.
      #
      #   request_headers['User-Agent'] = '...'

      ##
      # :call-seq:
      #   new(base_uri, http: nil)
      #   new(server_name, variables = nil, http: nil)
      #
      # Creates a client.
      #
      # Raises an +ArgumentError+ if +base_uri+ or +:http+ is invalid.
      def initialize(arg1, arg2 = nil, http: nil)
        unless arg1.is_a?(URI)
          server_url = self.class.api.server(arg1)&.url_for(arg2)
          arg1 = server_url unless server_url.nil?
          arg1 = URI(arg1)
        end

        @base_uri = arg1
        @host = @base_uri.host
        @port = @base_uri.port

        http = http&.dup || {}
        raise ArgumentError, ':http must be a hash' unless http.is_a?(Hash)

        @http_options = http
        @http_options[:use_ssl] = true if @base_uri.scheme == 'https'
      rescue URI::InvalidURIError => e
        raise ArgumentError, e
      end

      ##
      # :method: call
      # :call-seq:
      #   call(operation_name = nil, body = nil, content_type = nil, **params, &block)
      #
      # Calls a remote API operation and returns a Response. Returns +nil+ if no response
      # specification matches the status code returned by the server.
      #
      # If a block is given it is called with a Request as argument.
      #
      # Examples:
      #
      #   call('foo', id: 1)
      #
      #   call('foo') do |request|
      #     request[:id] = 1
      #     request.body = foo
      #   end
      #
      # +operation_name+ specifies the operation to be called. It can be omitted if the
      # remote API exposes a single operation. If the operation does not exist, an
      # OperationNotFound exception is raised.
      #
      # Raises a RequestError if the HTTP request cannot be be built from the given data.
      #
      # Raises a Session::Error if a session-level error occurs.

      ##
      # :method: call!
      # :call-seq:
      #   call!(operation_name = nil, body = nil, content_type = nil, **params, &block)
      #
      # Like +call+, except it raises a subclass of ResponseError when:
      #
      # - InvalidResponseBodyError - raised when the response body is invalid.
      # - UnexpectedResponseError - raised when no response specification matches the
      #   status code returned by the server.

      [true, false].each do |bang|
        define_method(bang ? :call! : :call) \
        do |operation_name = nil, body = nil, content_type = nil, **params, &block|
          operation = self.class.api.find_operation!(operation_name)

          request = Request.new(@base_uri, operation, headers: @request_headers, params: params)
          request.content_type = content_type || 'application/json'
          request.body = body
          instance_exec(request, &block) if block

          http_request = request.http_request

          session = @session || Session::SingleRequest.new(@host, @port, @logger, **@http_options)
          http_response = session.send_request(http_request)

          response_definition = operation.find_response_for(http_response.code)
          if response_definition.nil?
            raise UnexpectedResponseError.new(operation, http_response.code) if bang

            return
          end

          response = Response.new(http_response, response_definition)
          raise InvalidResponseBodyError.new(response.body) if bang && response.body.invalid?

          error_class = self.class.error_class_for(response.status_code)
          raise error_class, response.error_message if error_class

          response
        end
      end

      # Closes the current session.
      def finish_session
        @session&.finish
        @session = nil
      end

      def inspect # :nodoc:
        "#<#{self.class.name} base_uri: #{@base_uri}, http: #{@http_options.inspect}>"
      end

      def request_headers # :nodoc:
        @request_headers ||= Request::Headers.new
      end

      # Starts a session. If a block is given the session is closed automatically
      # after the block has been executed.
      #
      # Returns the value returned by the block or +nil+ if no block is given.
      #
      #   start_session do
      #     call('foo')
      #     call('bar')
      #   end
      #
      # Raises a Session::Error if a session-level error occurs.
      def start_session
        @session&.finish
        @session = Session::Base.new(@host, @port, @logger, **@http_options)

        if block_given?
          begin
            yield
          ensure
            finish_session
          end
        end
      end
    end
  end
end
