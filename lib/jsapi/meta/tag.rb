# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a tag.
    class Tag < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: description
      # The description of the tag.
      attribute :description, String

      ##
      # :attr: external_docs
      # The ExternalDocumentation object.
      attribute :external_docs, ExternalDocumentation

      ##
      # :attr: kind
      # The category of the tag. Applies to \OpenAPI 3.2 and higher.
      attribute :kind, String

      ##
      # :attr: name
      # The name of the tag.
      attribute :name, String

      ##
      # :attr: parent
      # The name of the parent tag. Applies to \OpenAPI 3.2 and higher.
      attribute :parent, String

      ##
      # :attr: summary
      # The short summary of the tag. Applies to \OpenAPI 3.2 and higher.
      attribute :summary, String

      # Returns a hash representing the \OpenAPI tag object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          if version >= OpenAPI::V3_2
            {
              name: name,
              summary: summary,
              description: description,
              externalDocs: external_docs&.to_openapi,
              parent: parent,
              kind: kind
            }
          else
            {
              name: name,
              description: description,
              externalDocs: external_docs&.to_openapi
            }
          end
        )
      end
    end
  end
end
