# frozen_string_literal: true

module Jsapi
  module Meta
    module SecurityScheme
      # Specifies a security scheme based on an API key.
      class APIKey < Base
        include OpenAPI::Extensions

        ##
        # :attr: in
        # The location of the API key. Possible values are:
        #
        # - <code>"cookie"</code>
        # - <code>"header"</code>
        # - <code>"query"</code>
        #
        attribute :in, String, values: %w[cookie header query]

        ##
        # :attr: name
        # The name of the header, query parameter or cookie the
        # API key is sent by.
        attribute :name, String

        # Returns a hash representing the \OpenAPI security scheme object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          openapi_security_scheme_object(
            'apiKey',
            version,
            name: name,
            in: self.in
          )
        end
      end
    end
  end
end
