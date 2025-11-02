# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      class PathItem # :nodoc:
        def initialize(operations)
          @operations = operations
        end

        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)

          {}.tap do |fields|
            @operations.each do |operation|
              method = operation.method
              standardized_method = method.downcase

              if standard_method?(standardized_method, version)
                fields[standardized_method] = operation.to_openapi(version, definitions)
              elsif version >= OpenAPI::V3_2
                additional_operations = fields[:additionalOperations] ||= {}
                additional_operations[method] = operation.to_openapi(version, definitions)
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
