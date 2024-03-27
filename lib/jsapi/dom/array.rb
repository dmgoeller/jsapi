# frozen_string_literal: true

module Jsapi
  module DOM
    # Represents a JSON array.
    class Array < Value
      def initialize(elements, schema, definitions)
        super(schema)
        @elements = Array(elements).map do |element|
          DOM.wrap(element, schema.items, definitions)
        end
      end

      # Returns +true+ if it contains no elements, +false+ otherwise.
      def empty?
        @elements.empty?
      end

      def inspect # :nodoc:
        "#<#{self.class.name} [#{@elements.map(&:inspect).join(', ')}]>"
      end

      # See Value#validate.
      def validate(errors)
        return false unless super

        @elements.map { |element| element.validate(errors) }.all?
      end

      def value
        @value ||= @elements.map(&:value)
      end
    end
  end
end
