# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        # Specifies a security scheme based on bearer authentication.
        #
        # Note that Bearer authentication was introduced with \OpenAPI 3.0. Thus, a security
        # scheme of this class is omitted when generating an \OpenAPI 2.0 document.
        class Bearer < Base
          include OpenAPI::Extensions

          ##
          # :attr: bearer_format
          # The format of the bearer token.
          attribute :bearer_format, String

          # Returns a hash representing the \OpenAPI security scheme object, or +nil+
          # if <code>version</code> is less than \OpenAPI 3.0.
          def to_openapi(version, *)
            version = OpenAPI::Version.from(version)
            return if version < OpenAPI::V3_0

            openapi_security_scheme_object(
              'http',
              version,
              scheme: 'bearer',
              bearerFormat: bearer_format
            )
          end
        end
      end
    end
  end
end
