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
      # :attr: name
      # The optional unique name of the server. Applies to \OpenAPI 3.2 and higher.
      attribute :name, String

      ##
      # :attr: url
      # The absolute or relative URL of the server.
      attribute :url, String

      ##
      # :attr_reader: variables
      # The ServerVariable objects.
      attribute :variables, { String => ServerVariable }

      # Returns a hash representing the \OpenAPI server object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          url: url,
          description: description,
          name: (name if version >= OpenAPI::V3_2),
          variables: variables.transform_values(&:to_openapi).presence
        )
      end
    end
  end
end
