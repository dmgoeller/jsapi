# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define a request body.
    class RequestBody < Schema
      include Examples

      ##
      # :method: deprecated
      # :args: arg
      # Specifies whether the request body is marked as deprecated.
      #
      #   deprecated true

      ##
      # :method: description
      # :args: arg
      # Specifies the description of the request body.
    end
  end
end
