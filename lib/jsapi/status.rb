# frozen_string_literal: true

require_relative 'status/base'
require_relative 'status/code'
require_relative 'status/default'
require_relative 'status/range'

module Jsapi
  # Provides classes to deal with response status codes.
  module Status
    class << self
      # Transforms +value+ to an instance of Base.
      #
      # Raises an +ArgumentError+ if +value+ could not be transformed.
      def from(value)
        return value if value.is_a?(Base)

        case value&.to_s
        when nil, 'default'
          DEFAULT
        when '1XX', '1xx'
          Range::INFORMATIONAL
        when '2XX', '2xx'
          Range::SUCCESS
        when '3XX', '3xx'
          Range::REDIRECTION
        when '4XX', '4xx'
          Range::CLIENT_ERROR
        when '5XX', '5xx'
          Range::SERVER_ERROR
        else
          Code.from(value)
        end
      end
    end
  end
end
