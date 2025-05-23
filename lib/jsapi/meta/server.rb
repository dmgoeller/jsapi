# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a server.
    class Server < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: description
      # The description of the server.
      attribute :description, String

      ##
      # :attr: url
      # The absolute or relative URL of the server.
      attribute :url, String

      ##
      # :attr_reader: variables
      # The ServerVariable objects.
      attribute :variables, { String => ServerVariable }

      # Returns a hash representing the \OpenAPI server object.
      def to_openapi(*)
        with_openapi_extensions(
          url: url,
          description: description,
          variables: variables.transform_values(&:to_openapi).presence
        )
      end
    end
  end
end
