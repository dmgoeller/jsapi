# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      class Logger
        def initialize(logger, **options)
          @logger = ActiveSupport::TaggedLogging.new(logger)
          @body = options[:body] == true
          @level = options[:level] || 0
        end

        # Logs +http_request+.
        def log_request(request)
          return if @logger.level > @level

          tagged('REQ') do
            log("#{request.method} #{request.path}")
            log(request.body, truncate_to: 8_192) if body?
          end
        end

        # Logs +http_response+.
        def log_response(response)
          return if @logger.level > @level

          tagged('RES') do
            log("HTTP/#{response.http_version} #{response.code}")
            log(response.body, truncate_to: 8_192) if body?
          end
        end

        private

        def body?
          @body == true
        end

        def log(message, truncate_to: nil)
          return if message.nil?

          message = message.truncate(truncate_to) if truncate_to
          @logger.log(@level, message)
        end

        def tagged(*args, &block)
          @logger.tagged('JSAPI CLIENT', *args, &block)
        end
      end
    end
  end
end
