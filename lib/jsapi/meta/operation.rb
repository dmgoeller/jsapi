# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies an API operation.
    class Operation < Model::Base
      include Model::Wrappable
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
      attribute :model, Class

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

      # Returns a hash representing the \OpenAPI operation object.
      def to_openapi(version, definitions)
        version = OpenAPI::Version.from(version)

        responses = (
          definitions
          &.common_responses(full_path)
          &.merge(self.responses) || self.responses
        ).reject { |_status, response| response.resolve(definitions).nodoc? }

        with_openapi_extensions(
          operationId: name,
          tags: [tags, definitions&.common_tags(full_path)].compact.flatten.uniq.presence,
          summary: summary,
          description: description,
          externalDocs: external_docs&.to_openapi,
          **if version == OpenAPI::V2_0
              resolved_request_body =
                (request_body || definitions.common_request_body(full_path))
                &.resolve(definitions)
              {
                consumes: [resolved_request_body&.default_media_range].compact.presence,
                produces: responses.values.filter_map do |response|
                  response.resolve(definitions).default_media_type
                end.uniq.sort.presence,
                schemes: schemes.presence,
                parameters:
                  begin
                    params = parameters.values.flat_map do |parameter|
                      parameter.to_openapi_parameters(version, definitions)
                    end
                    if resolved_request_body
                      params << resolved_request_body.to_openapi_parameter
                    end
                    params
                  end
              }
            else
              {
                servers: servers.map do |server|
                  server.to_openapi(version)
                end.presence,
                callbacks: callbacks.transform_values do |callback|
                  callback.to_openapi(version, definitions)
                end.presence,
                parameters: parameters.values.flat_map do |parameter|
                  parameter.to_openapi_parameters(version, definitions)
                end,
                request_body: request_body&.to_openapi(version)
              }
            end,
          responses: responses.transform_values do |response|
            response.to_openapi(version, definitions)
          end,
          deprecated: deprecated?.presence,
          security: security_requirements.map(&:to_openapi).presence
        )
      end

      class Wrapper < Model::Wrapper
        def full_path
          @full_path ||= super
        end

        def model
          return @model if defined? @model

          @model = super || definitions.common_model(full_path)
        end

        def parameters
          @parameters ||=
            (definitions.common_parameters(full_path)&.merge(super) || super)
            .transform_values { |parameter| Parameter.wrap(parameter, definitions) }
        end

        def request_body
          return @request_body if defined? @request_body

          @request_body = RequestBody.wrap(
            (super || definitions.common_request_body(full_path)),
            definitions
          )
        end

        def response(status)
          response = (@responses ||= {})[status = status.to_s]
          return response if response

          response = Response.wrap(
            (super || definitions.common_response(full_path, status)),
            definitions
          )
          @responses[status] = response if response
        end
      end
    end
  end
end
