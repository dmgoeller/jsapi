# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      class Error < StandardError; end
      class TimeoutError < Error; end

      # \Base session class.
      class Base
        include Test

        # Creates and starts a new session.
        def initialize(host, port = nil, logger = nil, **options)
          logger = Logger.new(logger) unless logger.nil? || logger.is_a?(Logger)
          @logger = logger

          @http =
            begin
              Net::HTTP.start(host, port, options)
            rescue StandardError => e
              raise wrap_error(e)
            end
        end

        # Closes the session.
        def finish
          @http.finish
        rescue StandardError => e
          raise wrap_error(e)
        end

        # Sends +request+.
        def send_request(request)
          @logger&.log_request(request)

          response =
            begin
              @http.request(request)
            rescue StandardError => e
              raise wrap_error(e)
            end

          @logger&.log_response(response)
          response
        end

        private

        def wrap_error(cause)
          case cause
          when Timeout::Error
            TimeoutError
          else
            Error
          end.new(cause: cause)
        end
      end
    end
  end
end
