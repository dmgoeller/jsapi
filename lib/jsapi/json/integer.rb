# frozen_string_literal: true

module Jsapi
  module JSON
    # Represents a JSON integer.
    class Integer < Value
      attr_reader :value

      def initialize(value, schema)
        super(schema)
        @value = schema.convert(
          begin
            value.to_i
          rescue StandardError => _e
            self.malformed = true
            0
          end
        )
      end
    end
  end
end
