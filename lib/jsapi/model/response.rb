# frozen_string_literal: true

module Jsapi
  module Model
    class Response
      include Examples

      attr_accessor :description
      attr_reader :schema

      def initialize(**options)
        @description = options[:description]
        @schema = Schema.new(**options.except(:description, :example))

        add_example(value: options[:example]) if options.key?(:example)
      end

      # Returns the OpenAPI response object as a +Hash+.
      def to_openapi_response(version)
        case version
        when '2.0'
          {
            description: description,
            schema: schema.to_openapi_schema(version),
            examples: (
              if examples.any?
                { 'application/json' => examples.values.first.value }
              end
            )
          }
        when '3.0.3'
          {
            description: description,
            content: {
              'application/json' => {
                schema: schema.to_openapi_schema(version),
                examples: openapi_examples.presence
              }.compact
            }
          }
        end.compact
      end
    end
  end
end
