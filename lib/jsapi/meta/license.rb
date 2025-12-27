# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a license.
    class License < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: identifier
      # The SDPX identifier of the license. Applies to \OpenAPI 3.1 and higher.
      attribute :identifier, String, accessors: %i[reader]

      ##
      # :attr: name
      # The name of the license.
      attribute :name, String

      ##
      # :attr: url
      # The URL of the license.
      attribute :url, String, accessors: %i[reader]

      def identifier=(identifier) # :nodoc:
        try_modify_attribute!(:identifier) do
          raise 'identifier and url are mutually exclusive' unless url.nil?

          @identifier = identifier
        end
      end

      def url=(url) # :nodoc:
        try_modify_attribute!(:url) do
          raise 'identifier and url are mutually exclusive' unless identifier.nil?

          @url = url
        end
      end

      # Returns a hash representing the \OpenAPI license object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          name: name,
          identifier: (identifier if version >= OpenAPI::V3_1),
          url: url
        )
      end
    end
  end
end
