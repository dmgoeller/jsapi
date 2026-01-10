# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies an API operation.
    class Operation < Model::Base
      include OpenAPI::Extensions

      class Wrapper < Model::Wrapper
        # Returns the most appropriate response for +status_code+.
        def find_response(status_code)
          status_code = Status::Code.from(status_code)

          responses.find do |status, _response|
            status.match?(status_code)
          end&.second
        end

        def full_path # :nodoc:
          @full_path ||= super
        end

        ##
        # :attr_reader: model
        # The model class of the wrapped operation or the default model class
        # for the path.

        # -
        def model
          return @model if defined? @model

          @model = super || definitions.common_model(full_path)
        end

        ##
        # :attr_reader: parameters
        # The parameters of the wrapped operation in combination with the
        # parameters applying to all operations in the path.

        # -
        def parameters
          @parameters ||=
            (definitions.common_parameters(full_path)&.merge(super) || super)
            .transform_values { |parameter| Parameter.wrap(parameter, definitions) }
        end

        ##
        # :attr_reader: request_body
        # The request body of the wrapped operation or the default request
        # body for the path.

        # -
        def request_body
          return @request_body if defined? @request_body

          @request_body = RequestBody.wrap(
            (super || definitions.common_request_body(full_path)),
            definitions
          )
        end

        ##
        # :attr_reader: responses
        # The responses of the wrapped operation in combination with the
        # responses applying to all operations in the path.

        # -
        def responses
          @responses ||=
            (definitions.common_responses(full_path)&.merge(super) || super)
            .transform_values { |response| Response.wrap(response, definitions) }
            .sort_by { |status, _response| status }
            .to_h
        end

        ##
        # :attr_reader: security_requirements
        # The security requirements of the wrapped operation in combination
        # with the security requirements applying to all operations in the
        # path or the default security requirements.

        # -
        def security_requirements
          return @security_requirements if defined? @security_requirements

          @security_requirements =
            [definitions.common_security_requirements(full_path), super]
              .compact.presence&.flatten ||
              definitions.default_security_requirements
        end
      end

      include Model::Wrappable

      ##
      # :attr: callbacks
      # The callbacks that can be triggered by the operation. Maps strings
      # to Callback objects or references.
      attribute :callbacks, { String => Callback }

      ##
      # :attr: deprecated
      # Specifies whether the operation is marked as deprecated.
      attribute :deprecated, values: [true, false]

      ##
      # :attr: description
      # The description of the operation.
      attribute :description, String

      ##
      # :attr: external_docs
      # The additional external documentation for this operation.
      #
      # See ExternalDocumentation for further information.
      attribute :external_docs, ExternalDocumentation

      ##
      # :attr: method
      # The HTTP method of the operation, <code>"get"</code> by default.
      attribute :method, String, default: 'get'

      ##
      # :attr: model
      # The model class to access top-level parameters by.
      attribute :model, Class

      ##
      # :attr_reader: name
      # The name of the operation.
      attribute :name, accessors: %i[reader]

      ##
      # :attr: parameters
      # The parameters of the operation. Maps parameter names to Parameter
      # objects or references.
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
      # The request body of the operation as a RequestBody object or reference.
      attribute :request_body, RequestBody

      ##
      # :attr: responses
      # The responses that can be produced by the operation. Maps instances of
      # Status::Base to Response objects or references.
      attribute :responses, { Status => Response }, default_key: Status::DEFAULT

      ##
      # :attr: schemes
      # The transfer protocols supported by the operation. Can contain one or
      # more of:
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
      # The security requirements that override the top-level security requirements.
      #
      # See SecurityRequirement for further information.
      attribute :security_requirements, [SecurityRequirement], default: :nil

      alias add_security add_security_requirement

      ##
      # :attr: servers
      # The servers providing the operation.
      #
      # Applies to \OpenAPI 3.0 and higher.
      #
      # See Server for further information.
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
        full_path = self.full_path

        responses = (
          definitions.common_responses(full_path)&.merge(self.responses) ||
          self.responses
        ).reject do |status, response|
          response.resolve(definitions).nodoc? ||
            version == OpenAPI::V2_0 && status.is_a?(Status::Range)
        end

        with_openapi_extensions(
          operationId: name,
          tags:
            [tags, definitions.common_tags(full_path)]
              .compact.flatten.uniq.presence,
          summary: summary,
          description: description,
          externalDocs: external_docs&.to_openapi,
          **if version == OpenAPI::V2_0
              resolved_request_body =
                (request_body || definitions.common_request_body(full_path))
                &.resolve(definitions)
              {
                consumes:
                  [resolved_request_body&.default_media_range]
                    .compact.presence,
                produces:
                  responses.values.filter_map do |response|
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
                servers:
                  servers.map do |server|
                    server.to_openapi(version)
                  end.presence,
                callbacks:
                  callbacks.transform_values do |callback|
                    callback.to_openapi(version, definitions)
                  end.presence,
                parameters:
                  parameters.values.flat_map do |parameter|
                    parameter.to_openapi_parameters(version, definitions)
                  end,
                request_body: request_body&.to_openapi(version)
              }
            end,
          responses:
            responses.transform_values do |response|
              response.to_openapi(version, definitions)
            end,
          deprecated: deprecated?.presence,
          security:
            [security_requirements, definitions.common_security_requirements(full_path)]
              .compact.presence&.flatten&.map(&:to_openapi)
        )
      end
    end
  end
end
