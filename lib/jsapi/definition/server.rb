# frozen_string_literal: true

module Jsapi
  module Definition
    # Specifies a server.
    class Server < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: description
      # The description of the server.
      attribute :description, String

      ##
      # :attr: name
      # The optional unique name of the server.
      #
      # Applies to \OpenAPI 3.2 and higher.
      attribute :name, String

      ##
      # :attr: url
      # The absolute or relative URL of the server.
      attribute :url, String

      ##
      # :attr_reader: variables
      # The server variables. Maps strings to ServerVariable objects.
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

      # Builds the URL for +variables+.
      def url_for(variables)
        variables = variables&.with_indifferent_access || {}

        url&.gsub(/\{\w+\}/) do |match|
          name = match[1..-2]
          value = variables[name]

          server_variable = variable(name)
          next value if server_variable.nil?
          next server_variable.default if value.nil?

          valid_values = server_variable.enum.presence
          next value unless valid_values&.exclude?(value)

          raise ArgumentError, Support::Messages.invalid_value(
            name: name,
            value: value,
            valid_values: valid_values
          )
        end
      end
    end
  end
end
