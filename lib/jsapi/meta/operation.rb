# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies an API operation.
    class Operation < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: callbacks
      # The Callback objects. Applies to \OpenAPI 3.0 and higher.
      attribute :callbacks, { String => Callback }

      ##
      # :attr: deprecated
      # Specifies whether or not the operation is deprecated.
      attribute :deprecated, values: [true, false]

      ##
      # :attr: description
      # The description of the operation.
      attribute :description, String

      ##
      # :attr: external_docs
      # The ExternalDocumentation object.
      attribute :external_docs, ExternalDocumentation

      ##
      # :attr: method
      # The HTTP method of the operation, <code>"get"</code> by default.
      attribute :method, String, default: 'get'

      ##
      # :attr: model
      # The model class to access top-level parameters by, Jsapi::Model::Base by default.
      attribute :model, Class, default: Jsapi::Model::Base

      ##
      # :attr_reader: name
      # The name of the operation.
      attribute :name, accessors: %i[reader]

      ##
      # :attr: parameters
      # The parameters of the operation.
      attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

      ##
      # :attr: path
      # The relative path of the operation.
      attribute :path, String

      ##
      # :attr: request_body
      # The request body of the operation.
      attribute :request_body, RequestBody

      ##
      # :attr: responses
      # The responses of the operation.
      attribute :responses, { String => Response }, default_key: 'default'

      ##
      # :attr: schemes
      # The transfer protocols supported by the operation. Possible values are:
      #
      # - <code>"http"</code>
      # - <code>"https"</code>
      # - <code>"ws"</code>
      # - <code>"wss"</code>
      #
      # Applies to \OpenAPI 2.0 only.
      attribute :schemes, [String], values: %w[http https ws wss]

      ##
      # :attr: security_requirements
      # The SecurityRequirement objects.
      attribute :security_requirements, [SecurityRequirement]

      alias add_security add_security_requirement

      ##
      # :attr: servers
      # The Server objects. Applies to \OpenAPI 3.0 and higher.
      attribute :servers, [Server]

      ##
      # :attr: summary
      # The short description of the operation.
      attribute :summary, String

      ##
      # :attr: tags
      # The tags used to group operations in an \OpenAPI document.
      attribute :tags, [String]

      def initialize(name = nil, keywords = {})
        @name = name&.to_s
        super(keywords)
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        (@parameters ||= {})[name.to_s] = Parameter.new(name, keywords)
      end

      # Returns the MIME type consumed by the operation.
      def consumes(definitions)
        request_body&.resolve(definitions)&.content_type
      end

      # Returns an array containing the MIME types produced by the operation.
      def produces(definitions)
        responses.values.filter_map do |response|
          response.resolve(definitions).content_type
        end.uniq.sort
      end

      # Returns a hash representing the \OpenAPI operation object.
      def to_openapi(version, definitions)
        version = OpenAPI::Version.from(version)

        with_openapi_extensions(
          operationId: name,
          tags: tags.presence,
          summary: summary,
          description: description,
          externalDocs: external_docs&.to_openapi,
          deprecated: deprecated?.presence,
          security: security_requirements.map(&:to_openapi).presence
        ).tap do |result|
          if version.major == 2
            if (consumes = consumes(definitions)).present?
              result[:consumes] = [consumes]
            end
            if (produces = produces(definitions)).present?
              result[:produces] = produces
            end
            result[:schemes] = schemes if schemes.present?
          elsif servers.present?
            result[:servers] = servers.map do |server|
              server.to_openapi(version)
            end
          end
          # Parameters (and request body)
          result[:parameters] = parameters.values.flat_map do |parameter|
            parameter.to_openapi_parameters(version, definitions)
          end
          if request_body
            if version.major == 2
              result[:parameters] << request_body.resolve(definitions).to_openapi_parameter
            else
              result[:request_body] = request_body.to_openapi(version)
            end
          end
          # Responses
          result[:responses] = responses.transform_values do |response|
            response.to_openapi(version, definitions)
          end
          # Callbacks
          if callbacks.present? && version.major > 2
            result[:callbacks] = callbacks.transform_values do |callback|
              callback.to_openapi(version, definitions)
            end
          end
        end
      end
    end
  end
end
