# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      module HTTP
        # Specifies a security scheme based on \HTTP basic authentication.
        class Basic < Base
          include OpenAPI::Extensions

          # Returns a hash representing the \OpenAPI security scheme object.
          def to_openapi(version, *)
            version = OpenAPI::Version.from(version)

            if version < OpenAPI::V3_0
              openapi_security_scheme_object('basic', version)
            else
              openapi_security_scheme_object('http', version, scheme: 'basic')
            end
          end
        end
      end
    end
  end
end
