# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      class Base < Model::Base
        ##
        # :attr: description
        # The description of the security scheme.
        attribute :description, String

        ##
        # :attr: deprecated
        # Specifies whether the security scheme is marked as deprecated.
        #
        # Applies to \OpenAPI 3.2 and higher.
        attribute :deprecated, values: [true, false]

        private

        def base_openapi_fields(type, version)
          {
            type: type,
            description: description,
            deprecated: (deprecated?.presence if version >= OpenAPI::V3_2)
          }
        end
      end
    end
  end
end
