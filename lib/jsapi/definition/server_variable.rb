# frozen_string_literal: true

module Jsapi
  module Definition
    # Specifies a server variable.
    class ServerVariable < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: default
      # The default value of the server variable.
      attribute :default, String

      ##
      # :attr: description
      # The description of the server variable.
      attribute :description, String

      ##
      # :attr: enum
      # The values of the server variable.
      attribute :enum, [String]

      # Returns a hash representing the \OpenAPI server variable object.
      def to_openapi(*)
        with_openapi_extensions(
          default: default,
          enum: enum.presence,
          description: description
        )
      end
    end
  end
end
