# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        # Specifies a security scheme based on bearer authentication.
        #
        # Note that Bearer authentication was introduced with \OpenAPI 3.0. Thus, a security
        # scheme of this class is skipped when generating an \OpenAPI 2.0 document.
        class Bearer < Base
          include OpenAPI::Extensions

          ##
          # :attr: bearer_format
          # The format of the bearer token.
          attribute :bearer_format, String

          # Returns a hash representing the \OpenAPI security scheme object, or
          # +nil+ if <code>version.major</code> is 2.
          def to_openapi(version, *)
            version = OpenAPI::Version.from(version)
            return if version.major == 2

            with_openapi_extensions(
              type: 'http',
              scheme: 'bearer',
              bearerFormat: bearer_format,
              description: description
            )
          end
        end
      end
    end
  end
end
