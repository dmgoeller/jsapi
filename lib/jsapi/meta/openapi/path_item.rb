# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      class PathItem # :nodoc:
        def initialize(operations, keywords = {})
          @operations = operations
          @summary = keywords[:summary]
          @description = keywords[:description]
          @servers = keywords[:servers]
          @parameters = keywords[:parameters]
        end

        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)

          {}.tap do |fields|
            if version >= OpenAPI::V3_0
              fields[:summary] = @summary if @summary.present?
              fields[:description] = @description if @description.present?
            end

            # Operations
            @operations&.each do |operation|
              method = operation.method
              standardized_method = method.downcase

              if standard_method?(standardized_method, version)
                fields[standardized_method] = operation.to_openapi(version, definitions)
              elsif version >= OpenAPI::V3_2
                additional_operations = fields[:additionalOperations] ||= {}
                additional_operations[method] = operation.to_openapi(version, definitions)
              end
            end

            # Servers
            if version >= OpenAPI::V3_0 && @servers.present?
              fields[:servers] = @servers.map { |server| server.to_openapi(version) }
            end

            # Parameters
            if @parameters.present?
              fields[:parameters] = @parameters.values.map do |parameter|
                parameter.to_openapi(version, definitions)
              end
            end
          end
        end

        private

        def standard_method?(method, version)
          case method
          when 'delete', 'get', 'head', 'options', 'patch', 'post', 'put'
            true
          when 'trace'
            version >= OpenAPI::V3_0
          when 'query'
            version >= OpenAPI::V3_2
          else
            false
          end
        end
      end
    end
  end
end
