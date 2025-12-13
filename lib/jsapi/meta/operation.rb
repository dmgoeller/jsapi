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
      # :attr_reader: parent_path
      # The parent path as a Pathname.
      attribute :parent_path, Pathname, accessors: %i[reader]

      ##
      # :attr: path
      # The relative path of the operation as a Pathname.
      attribute :path, Pathname

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

      def initialize(name, parent_path = nil, keywords = {})
        parent_path, keywords = nil, parent_path if parent_path.is_a?(Hash)

        @name = name&.to_s
        @parent_path = Pathname.from(parent_path)
        super(keywords)
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        try_modify_attribute!(:parameters) do
          name = name.to_s

          (@parameters ||= {})[name.to_s] = Parameter.new(name, keywords)
        end
      end

      # Returns the full path of the operation as a Pathname.
      def full_path
        parent_path + path
      end

      # Merges the parameters of this operation and the common parameters of all
      # parent pathes and resolves them.
      def resolved_parameters(definitions)
        (definitions.path_parameters(full_path).presence&.merge(parameters) || parameters)
          .transform_values { |parameter| parameter.resolve(definitions) }
      end

      # Returns a hash representing the \OpenAPI operation object.
      def to_openapi(version, definitions)
        version = OpenAPI::Version.from(version)
        resolved_request_body = request_body&.resolve(definitions)

        with_openapi_extensions(
          operationId: name,
          tags: tags.presence,
          summary: summary,
          description: description,
          externalDocs: external_docs&.to_openapi,
          **if version == OpenAPI::V2_0
              {
                consumes: [resolved_request_body&.default_media_range].compact,
                produces: responses.values.filter_map do |response|
                  response.resolve(definitions).default_media_type
                end.uniq.sort,
                schemes: schemes
              }
            else
              {
                servers: servers.map do |server|
                  server.to_openapi(version)
                end
              }
            end.compact_blank,
          parameters:
            begin
              params = parameters.values.flat_map do |parameter|
                parameter.to_openapi_parameters(version, definitions)
              end
              if version == OpenAPI::V2_0 && resolved_request_body
                params << resolved_request_body.to_openapi_parameter
              end
              params
            end,
          request_body:
            if version >= OpenAPI::V3_0
              request_body&.to_openapi(version)
            end,
          responses:
            responses.transform_values do |response|
              response.to_openapi(version, definitions)
            end,
          callbacks:
            if version >= OpenAPI::V3_0
              callbacks.transform_values do |callback|
                callback.to_openapi(version, definitions)
              end.presence
            end,
          deprecated: deprecated?.presence,
          security: security_requirements.map(&:to_openapi).presence
        )
      end
    end
  end
end
