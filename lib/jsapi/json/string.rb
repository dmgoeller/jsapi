# frozen_string_literal: true

module Jsapi
  module JSON
    # Represents a JSON string.
    class String < Value
      attr_reader :value

      def initialize(value, schema)
        super(schema)

        @value =
          begin
            case schema.format
            when 'date'
              value.to_date
            when 'date-time'
              value.to_datetime
            when 'duration'
              ActiveSupport::Duration.parse(value)
            else
              value.to_s
            end
          rescue StandardError => _e
            self.malformed = true
            value
          end
        @value = schema.convert(@value) unless malformed?
      end

      def empty? # :nodoc:
        value.blank?
      end
    end
  end
end
