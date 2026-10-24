# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class MultipleOf < Base
          def initialize(value)
            unless value.respond_to?(:%)
              raise ArgumentError, "invalid multiple of: #{value.inspect}"
            end

            super
          end

          def validate(value, errors)
            return true if (value % self.value).zero?

            errors.add(:base, :invalid)
            false
          end
        end
      end
    end
  end
end
