# frozen_string_literal: true

module Jsapi
  module Meta
    module RequestBody
      # Specifies a request body.
      class Base < Model::Base
        include OpenAPI::Extensions

        delegate_missing_to :schema

        ##
        # :attr: content_type
        # The content type. <code>"application/json"</code> by default.
        attribute :content_type, String, default: 'application/json'

        ##
        # :attr: description
        # The description of the request body.
        attribute :description, String

        ##
        # :attr_reader: examples
        # The Example objects.
        attribute :examples, { String => Example }, default_key: 'default'

        ##
        # :attr_reader: schema
        # The Schema of the request body.
        attribute :schema, accessors: %i[reader]

        def initialize(keywords = {})
          keywords = keywords.dup
          super(keywords.extract!(:content_type, :description, :examples, :openapi_extensions))

          add_example(value: keywords.delete(:example)) if keywords.key?(:example)
          keywords[:ref] = keywords.delete(:schema) if keywords.key?(:schema)

          @schema = Schema.new(keywords)
        end

        # Returns true if the level of existence is greater than or equal to
        # +ALLOW_NIL+, false otherwise.
        def required?
          schema.existence >= Existence::ALLOW_NIL
        end

        # Returns a hash representing the \OpenAPI 2.0 parameter object.
        def to_openapi_parameter
          with_openapi_extensions(
            {
              name: 'body',
              in: 'body',
              description: description,
              required: required?,
              **schema.to_openapi(OpenAPI::V2_0)
            }
          )
        end

        # Returns a hash representing the \OpenAPI 3.x request body object.
        def to_openapi(version, *)
          with_openapi_extensions(
            description: description,
            content: {
              content_type => {
                schema: schema.to_openapi(version),
                examples: examples.transform_values(&:to_openapi).presence
              }.compact
            },
            required: required?
          )
        end
      end
    end
  end
end
