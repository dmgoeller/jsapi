# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      # Represents an OAuth flow object.
      class OAuthFlow < Base::Model
        include Extensions

        class Scope < Meta::Base::Model
          ##
          # :attr: description
          # The optional description of the scope.
          attribute :description, String, default: ''
        end

        ##
        # :attr: authorization_url
        # The authorization URL to be used for the flow.
        attribute :authorization_url, String

        ##
        # :attr: refresh_url
        # The refresh URL to be used for the flow.
        #
        # Note that the refresh URL was introduced with \OpenAPI 3.0. It is
        # skipped when generating an \OpenAPI 2.0 document.
        attribute :refresh_url, String

        ##
        # :attr: scopes
        # The hash containing the scopes.
        attribute :scopes, { String => Scope }, default: {}

        ##
        # :attr: token_url
        # The token URL to be used for the flow.
        attribute :token_url, String

        # Returns a hash representing the \OpenAPI OAuth flow object.
        def to_openapi(version)
          with_openapi_extensions(
            authorizationUrl: authorization_url,
            tokenUrl: token_url,
            refreshUrl: (refresh_url if version.major > 2),
            scopes: scopes.transform_values(&:description)
          )
        end
      end
    end
  end
end
