# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      module Test
        # Spies an HTTP session.
        class Spy
          ##
          # :attr_reader: request
          # The last captured request.
          attr_reader :request

          def initialize(...)
            @response = Response.new(...)
            @finished = false
          end

          # Mimics +finish+ of Session::Base.
          def finish
            @finished = true
          end

          # Returns true if +finish+ has been called before.
          def finished?
            @finished == true
          end

          # Sets the response for subsequent calls.
          def response_with(...)
            @response = Response.new(...)
          end

          # Mimics +send_request+ of Session::Base.
          def send_request(request)
            @request = request
            @response
          end
        end
      end
    end
  end
end
