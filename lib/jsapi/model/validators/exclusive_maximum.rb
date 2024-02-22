# frozen_string_literal: true

module Jsapi
  module Model
    module Validators
      class ExclusiveMaximum
        def initialize(exclusive_maximum)
          unless exclusive_maximum.respond_to?(:>=)
            raise ArgumentError, "invalid exclusive maximum: #{exclusive_maximum}"
          end

          @exclusive_maximum = exclusive_maximum
        end

        def validate(object)
          if object.value >= @exclusive_maximum
            object.errors.add(:less_than, count: @exclusive_maximum)
          end
        end
      end
    end
  end
end