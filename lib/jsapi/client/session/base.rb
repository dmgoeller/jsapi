# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      class Error < StandardError; end

      class Base
        include Test

        # Creates and starts a new session.
        def initialize(host, port = nil, **options)
          @http = Net::HTTP.start(host, port, options)
        rescue StandardError => e
          raise Error, e
        end

        # Finishes the session.
        def finish
          @http.finish
        rescue StandardError => e
          raise Error, e
        end

        # Sends +request+.
        def send_request(request)
          @http.request(request)
        rescue StandardError => e
          raise Error, e
        end
      end
    end
  end
end
