# frozen_string_literal: true

module Jsapi
  module JSON
    # Represents a JSON object.
    class Object < Value
      include Model::Nestable

      alias serializable_value serializable_hash

      attr_reader :raw_additional_attributes, :raw_attributes

      def initialize(hash, schema, definitions, context: nil)
        schema = schema.resolve_schema(hash, definitions, context: context)
        properties = schema.resolve_properties(definitions, context: context)

        @raw_attributes = properties.transform_values do |property|
          JSON.wrap(hash[property.name], property.schema, definitions, context: context)
        end

        @raw_additional_attributes =
          if (additional_properties = schema.additional_properties)
            additional_properties_schema = additional_properties.schema.resolve(definitions)

            hash.except(*properties.keys).transform_values do |value|
              JSON.wrap(value, additional_properties_schema, definitions, context: context)
            end
          end || {}

        super(schema)
      end

      # Returns true if all attributes are empty, false otherwise.
      def empty?
        @raw_attributes.values.all?(&:empty?)
      end

      # Returns a model to read attributes by.
      def model
        @model ||= (schema.model || Model::Base).new(self)
      end

      alias value model

      # See Value#validate
      def validate(errors)
        return false unless super

        validate_attributes(errors)
      end
    end
  end
end
