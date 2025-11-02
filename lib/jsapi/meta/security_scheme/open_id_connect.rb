# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      # Specifies a security scheme based on OpenID Connect.
      class OpenIDConnect < Base
        include OpenAPI::Extensions

        ##
        # :attr: open_id_connect_url
        attribute :open_id_connect_url, String

        # Returns a hash representing the \OpenAPI security scheme object, or +nil+
        # if <code>version</code> is less than \OpenAPI 3.0.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)
          return if version < OpenAPI::V3_0

          with_openapi_extensions(
            base_openapi_fields('openIdConnect', version).merge(
              openIdConnectUrl: open_id_connect_url
            )
          )
        end
      end
    end
  end
end
