# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies the content of a request body or response.
    class Content < Model::Base
      include OpenAPI::Extensions

      class Wrapper < Model::Wrapper
        def schema
          @schema ||= Schema.wrap(super, definitions)
        end
      end

      include Model::Wrappable

      delegate_missing_to :schema

      ##
      # :attr: examples
      # The examples. Maps example names to Example objects or references.
      attribute :examples, { String => Example }, default_key: 'default'

      ##
      # :attr_reader: schema
      # The Schema of the content.
      attribute :schema, accessors: %i[reader]

      def initialize(keywords = {})
        keywords = keywords.dup
        super(keywords.extract!(:examples, :openapi_extensions))

        add_example(value: keywords.delete(:example)) if keywords.key?(:example)
        keywords[:ref] = keywords.delete(:schema) if keywords.key?(:schema)

        @schema = Schema.new(keywords)
      end

      # Returns the data value of the first example.
      def example_data_value(definitions, locale: nil)
        examples
          .values.first
          &.resolve(definitions)
          &.data_value(builder: example_builder(definitions, locale))
      end

      # Returns a hash representing the \OpenAPI media type object describing
      # the content. Applies to \OpenAPI 3.0 and higher.
      def to_openapi(version, definitions = nil, locale: nil, media_type: nil)
        version = OpenAPI::Version.from(version)
        example_builder = nil

        with_openapi_extensions(
          **if media_type == Media::Type::APPLICATION_JSON_SEQ &&
               schema.array? && version >= OpenAPI::V3_2
              { itemSchema: schema.items.to_openapi(version) }
            else
              { schema: schema.to_openapi(version) }
            end,
          examples:
            examples.transform_values do |example|
              example_builder ||= example_builder(definitions, locale)
              example.to_openapi(version, builder: example_builder)
            end.presence
        )
      end

      private

      def example_builder(definitions, locale)
        Example::Builder.new(schema, definitions, locale: locale) if definitions.present?
      end
    end
  end
end
