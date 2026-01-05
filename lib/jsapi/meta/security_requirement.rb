# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a security requirement.
    class SecurityRequirement < Model::Base
      class Scheme < Model::Base
        ##
        # :attr: scopes
        # The scopes.
        attribute :scopes, [String]
      end

      ##
      # :attr_reader: schemes
      # The schemes. Maps strings to Scheme objects.
      attribute :schemes, { String => Scheme }

      # Returns a hash representing the \OpenAPI security requirement object.
      def to_openapi(*)
        schemes.transform_values(&:scopes)
      end
    end
  end
end
