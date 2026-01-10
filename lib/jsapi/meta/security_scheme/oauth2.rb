# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      # Specifies a security scheme based on \OAuth2.
      class OAuth2 < Base
        include OpenAPI::Extensions

        ##
        # :attr: oauth_flows
        # Maps one or more of the following keys to OAuthFlow objects.
        #
        # - <code>"authorization_code"</code>
        # - <code>"client_credentials"</code>
        # - <code>"device_authorization"</code>
        # - <code>"implicit"</code>
        # - <code>"password"</code>
        #
        # Note that <code>"device_authorization"</code> was introduced with \OpenAPI 3.2.
        # This entry is omitted when generating an \OpenAPI document with a lower version.
        attribute :oauth_flows, { String => OAuthFlow },
                  keys: %w[authorization_code
                           client_credentials
                           device_authorization
                           implicit
                           password]

        ##
        # :attr: oauth2_metadata_url
        # The URL of the OAuth2 authorization server metadata.
        #
        # Applies to \OpenAPI 3.2 and higher.
        attribute :oauth2_metadata_url, String

        # Returns a hash representing the \OpenAPI security scheme object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          flows = oauth_flows
          flows = flows.except('device_authorization') if version < OpenAPI::V3_2

          openapi_security_scheme_object(
            'oauth2',
            version,
            **if version >= OpenAPI::V3_0
                {
                  flows:
                    flows.to_h do |key, value|
                      [key.to_s.camelize(:lower), value.to_openapi(version)]
                    end.presence,
                  oauth2MetadataUrl: (oauth2_metadata_url if version >= OpenAPI::V3_2)
                }
              elsif flows.one?
                key, flow = flows.first
                { flow: key, **flow.to_openapi(version) }
              else
                {}
              end
          )
        end
      end
    end
  end
end
