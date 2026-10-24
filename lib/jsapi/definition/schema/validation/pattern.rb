# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class Pattern < Base
          def initialize(value)
            unless value.is_a?(Regexp)
              raise ArgumentError, "invalid pattern: #{value.inspect}"
            end

            super
          end

          def validate(value, errors)
            return true if value.to_s.match?(self.value)

            errors.add(:base, :invalid)
            false
          end

          def to_json_schema_validation
            { pattern: value.source }
          end
        end
      end
    end
  end
end
