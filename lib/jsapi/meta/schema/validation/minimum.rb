# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      module Validation
        class Minimum < Base
          attr_reader :exclusive

          def initialize(value, exclusive: false)
            if exclusive
              unless value.respond_to?(:>)
                raise ArgumentError, "invalid exclusive minimum: #{value.inspect}"
              end
            else
              unless value.respond_to?(:>=)
                raise ArgumentError, "invalid minimum: #{value.inspect}"
              end
            end

            super(value)
            @exclusive = exclusive
          end

          def validate(value, errors)
            if exclusive
              return true if value > self.value

              errors.add(:base, :greater_than, count: self.value)
            else
              return true if value >= self.value

              errors.add(:base, :greater_than_or_equal_to, count: self.value)
            end
            false
          end

          def to_json_schema_validation
            return super unless exclusive

            { exclusiveMinimum: value }
          end

          def to_openapi_validation(version)
            version = OpenAPI::Version.from(version)
            return to_json_schema_validation if version >= OpenAPI::V3_1
            return super unless exclusive

            { minimum: value, exclusiveMinimum: true }
          end
        end
      end
    end
  end
end
