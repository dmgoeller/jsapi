# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      # Specifies a security scheme based on MutualTLS.
      class MutualTLS < Base
        include OpenAPI::Extensions

        # Returns a hash representing the \OpenAPI security scheme object, or +nil+
        # if <code>version</code> is less than \OpenAPI 3.1.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)
          return if version < OpenAPI::V3_1

          with_openapi_extensions(
            base_openapi_fields('mutualTLS', version)
          )
        end
      end
    end
  end
end
