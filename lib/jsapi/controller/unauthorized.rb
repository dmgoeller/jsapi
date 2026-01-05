# frozen_string_literal: true

module Jsapi
  module Controller
    # Raised by Methods#api_operation and Methods#api_operation! when the
    # current request could not be authenticated.
    class Unauthorized < StandardError
      def initialize # :nodoc:
        super('request could not be authenticated')
      end
    end
  end
end
