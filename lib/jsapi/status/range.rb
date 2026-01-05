# frozen_string_literal: true

module Jsapi
  module Status
    # Represents a range of status codes.
    class Range < Base
      def initialize(hundreds) # :nodoc:
        super("#{hundreds}XX", priority: 2)

        range_begin = hundreds * 100
        @range = (range_begin..(range_begin + 99))
      end

      # The range of informational status codes (1xx).
      INFORMATIONAL = Range.new(1)

      # The range of success status codes (2xx).
      SUCCESS = Range.new(2)

      # The range of redirection status codes (3xx).
      REDIRECTION = Range.new(3)

      # The range of client error status codes (4xx).
      CLIENT_ERROR = Range.new(4)

      # The range of server error status codes (5xx).
      SERVER_ERROR = Range.new(5)

      # Returns true if the range covers +status_code+.
      def match?(status_code)
        @range.cover?(status_code.value) if status_code
      end
    end
  end
end
