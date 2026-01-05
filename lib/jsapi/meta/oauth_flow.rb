# frozen_string_literal: true

module Jsapi
  module Meta
    # Represents an OAuth flow object.
    class OAuthFlow < Model::Base
      include OpenAPI::Extensions

      class Scope < Model::Base
        ##
        # :attr: description
        # The description of the scope.
        attribute :description, String, default: ''
      end

      ##
      # :attr: authorization_url
      # The authorization URL to be used for the flow.
      attribute :authorization_url, String

      ##
      # :attr: device_authorization_url
      # The device authorization URL to be used for the flow.
      #
      # Note that the device authorization URL was introduced with \OpenAPI 3.2.
      # It is omitted when generating an \OpenAPI document with a lower version.
      attribute :device_authorization_url, String

      ##
      # :attr: refresh_url
      # The refresh URL to be used for the flow.
      #
      # Note that the refresh URL was introduced with \OpenAPI 3.0. It is
      # omitted when generating an \OpenAPI document with a lower version.
      attribute :refresh_url, String

      ##
      # :attr: scopes
      # The scopes. Maps strings to Scope objects.
      attribute :scopes, { String => Scope }

      ##
      # :attr: token_url
      # The token URL to be used for the flow.
      attribute :token_url, String

      # Returns a hash representing the \OpenAPI OAuth flow object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          authorizationUrl: authorization_url,
          deviceAuthorizationUrl: (device_authorization_url if version >= OpenAPI::V3_2),
          tokenUrl: token_url,
          refreshUrl: (refresh_url if version >= OpenAPI::V3_0),
          scopes: scopes.transform_values(&:description)
        )
      end
    end
  end
end
