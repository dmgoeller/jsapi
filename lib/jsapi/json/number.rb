# frozen_string_literal: true

module Jsapi
  module JSON
    # Represents a JSON number.
    class Number < Value
      attr_reader :value

      def initialize(value, schema)
        super(schema)
        @value = schema.convert(
          begin
            value.to_f
          rescue StandardError => _e
            self.malformed = true
            0.0
          end
        )
      end
    end
  end
end
