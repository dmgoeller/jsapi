# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class MinItems < Base
          def initialize(value)
            unless value.respond_to?(:>=)
              raise ArgumentError, "invalid min items: #{value.inspect}"
            end

            super
          end

          def validate(value, errors)
            return true if value.size >= self.value

            errors.add(:base, :invalid)
            false
          end
        end
      end
    end
  end
end
