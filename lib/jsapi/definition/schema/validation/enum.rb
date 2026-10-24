# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class Enum < Base
          def initialize(value)
            unless value.respond_to?(:include?)
              raise ArgumentError, "invalid enum: #{value.inspect}"
            end

            super
          end

          def validate(value, errors)
            return true if self.value.include?(value)

            errors.add(:base, :inclusion)
            false
          end
        end
      end
    end
  end
end
