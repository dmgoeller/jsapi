# frozen_string_literal: true

module Jsapi
  module Meta
    module Link
      # Specifies a link.
      class Base < Model::Base
        include OpenAPI::Extensions

        ##
        # :attr: description
        # The description of the link.
        attribute :description, String

        ##
        # :attr: operation_id
        # The operation ID.
        attribute :operation_id, String

        ##
        # :attr: parameters
        # The parameters to be passed.
        attribute :parameters, { String => Object }

        ##
        # :attr: request_body
        # The request body to be passed.
        attribute :request_body

        ##
        # :attr: server
        # The Server object.
        attribute :server, Server

        # Returns a hash representing the \OpenAPI link object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            operationId: operation_id,
            parameters: parameters.presence,
            requestBody: request_body,
            description: description,
            server: server&.to_openapi(version)
          )
        end
      end
    end
  end
end
