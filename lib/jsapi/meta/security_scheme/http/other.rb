# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        # Specifies a security scheme based on any other \HTTP authentication than basic
        # and bearer.
        #
        # Note that \OpenAPI 2.0 supports \HTTP basic authentication only. Thus, a security
        # scheme of this class is skipped when generating an \OpenAPI 2.0 document.
        class Other < Base
          include OpenAPI::Extensions

          ##
          # :attr: scheme
          # The mandatory \HTTP authentication scheme.
          attribute :scheme, String

          # Returns a hash representing the \OpenAPI security scheme object, or +nil+
          # if <code>version</code> is less than \OpenAPI 3.0.
          def to_openapi(version, *)
            version = OpenAPI::Version.from(version)
            return if version < OpenAPI::V3_0

            openapi_security_scheme_object('http', version, scheme: scheme)
          end
        end
      end
    end
  end
end
