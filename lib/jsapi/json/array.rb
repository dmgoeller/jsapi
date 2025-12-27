# frozen_string_literal: true

module Jsapi
  module JSON
    # Represents a JSON array.
    class Array < Value
      def initialize(array, schema, context: nil)
        super(schema)
        @json_values = Array(array).map do |item|
          JSON.wrap(item, schema.items, context: context)
        end
      end

      # Returns true if it contains no elements, false otherwise.
      def empty?
        @json_values.empty?
      end

      def inspect # :nodoc:
        "#<#{self.class.name} [#{@json_values.map(&:inspect).join(', ')}]>"
      end

      def serializable_value(**options) # :nodoc:
        @json_values.map { |element| element.serializable_value(**options) }
      end

      def validate(errors) # :nodoc:
        return false unless super

        @json_values.map { |element| element.validate(errors) }.all?
      end

      def value
        @value ||= @json_values.map(&:value)
      end
    end
  end
end
