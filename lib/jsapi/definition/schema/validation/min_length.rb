# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class MinLength < Base
          def initialize(value)
            unless value.respond_to?(:>=)
              raise ArgumentError, "invalid min length: #{value.inspect}"
            end

            super
          end

          def validate(value, errors)
            return true if value.to_s.length >= self.value

            errors.add(:base, :too_short, count: self.value)
            false
          end
        end
      end
    end
  end
end
