# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Discriminator < Model::Base
        include OpenAPI::Extensions

        ##
        # :attr: default_mapping
        # Applies to \OpenAPI 3.2 and higher.
        attribute :default_mapping, String

        ##
        # :attr: mappings
        # Applies to \OpenAPI 3.0 and higher.
        attribute :mappings, { Object => String }

        ##
        # :attr: property_name
        attribute :property_name, String

        # Returns a hash representing the \OpenAPI discriminator object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)
          return property_name if version < OpenAPI::V3_0

          result = {
            propertyName: property_name,
            mapping: mappings.transform_keys(&:to_s).presence,
            defaultMapping: (default_mapping if version >= OpenAPI::V3_2)
          }
          version >= OpenAPI::V3_1 ? with_openapi_extensions(result) : result.compact
        end
      end
    end
  end
end
