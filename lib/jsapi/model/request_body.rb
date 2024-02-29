# frozen_string_literal: true

module Jsapi
  module Model
    class RequestBody
      include Examples

      attr_accessor :description
      attr_reader :schema

      def initialize(**options)
        @description = options[:description]
        @schema = Schema.new(**options.except(:description, :example))

        add_example(value: options[:example]) if options.key?(:example)
      end

      def required?
        schema.existence > Existence::ALLOW_OMITTED
      end

      # Returns the OpenAPI 3.x request body object as a +Hash+.
      def to_openapi_request_body
        {
          description: description,
          content: {
            'application/json' => {
              schema: schema.to_openapi_schema('3.0.3'),
              examples: openapi_examples.presence
            }.compact
          },
          required: required?
        }.compact
      end

      # Returns the OpenAPI 2.0 parameter object as a +Hash+.
      def to_openapi_parameter
        {
          name: 'body',
          in: 'body',
          required: required?
        }.merge(schema.to_openapi_schema('2.0'))
      end
    end
  end
end
