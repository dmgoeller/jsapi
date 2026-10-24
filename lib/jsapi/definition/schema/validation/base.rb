# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      module Validation
        class Base
          def self.keyword
            @keyword ||= name.demodulize.camelize(:lower).to_sym
          end

          attr_reader :value

          def initialize(value)
            @value = value
          end

          def to_json_schema_validation
            { self.class.keyword => value }
          end

          def to_openapi_validation(*)
            to_json_schema_validation
          end
        end
      end
    end
  end
end
