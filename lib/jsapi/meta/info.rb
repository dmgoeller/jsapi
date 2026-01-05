# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies metadata about an API.
    class Info < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: contact
      # The Contact.
      attribute :contact, Contact

      ##
      # :attr: description
      # The description of the API.
      attribute :description, String

      ##
      # :attr: license
      # The License.
      attribute :license, License

      ##
      # :attr: summary
      # The short summary of the API.
      #
      # Applies to \OpenAPI 3.1 and higher.
      attribute :summary, String

      ##
      # :attr: terms_of_service
      # The URL pointing to the terms of service.
      attribute :terms_of_service, String

      ##
      # :attr: title
      # The title of the API.
      attribute :title, String

      ##
      # :attr: version
      # The version of the API.
      attribute :version, String

      # Returns a hash representing the \OpenAPI info object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          title: title,
          summary: (summary if version >= OpenAPI::V3_1),
          description: description,
          termsOfService: terms_of_service,
          contact: contact&.to_openapi,
          license: license&.to_openapi(version),
          version: self.version
        )
      end
    end
  end
end
