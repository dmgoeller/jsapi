# frozen_string_literal: true

module Jsapi
  module Meta
    module Response
      # Specifies a response.
      class Base < Model::Base
        include OpenAPI::Extensions

        JSON_TYPE = %r{(^application/|^text/|\+)json$}.freeze # :nodoc:
        JSON_SEQ_TYPE = 'application/json-seq' # :nodoc:

        delegate_missing_to :schema

        ##
        # :attr: content_type
        # The content type, <code>"application/json"</code> by default.
        attribute :content_type, String, default: 'application/json'

        ##
        # :attr: description
        # The description of the response.
        attribute :description, String

        ##
        # :attr: examples
        # The Example objects.
        attribute :examples, { String => Example }, default_key: 'default'

        ##
        # :attr: headers
        # The Header objects.
        attribute :headers, { String => Header }

        ##
        # :attr: links
        # The Link objects.
        attribute :links, { String => Link }

        ##
        # :attr: locale
        # The locale used when rendering a response.
        attribute :locale, Symbol

        ##
        # :attr_reader: schema
        # The Schema of the response.
        attribute :schema, accessors: %i[reader]

        ##
        # :attr: summary
        # The short description of the response. Applies to \OpenAPI 3.2 and higher.
        attribute :summary, String

        def initialize(keywords = {})
          keywords = keywords.dup
          super(
            keywords.extract!(
              :content_type, :description, :examples, :headers,
              :links, :locale, :openapi_extensions, :summary
            )
          )
          add_example(value: keywords.delete(:example)) if keywords.key?(:example)
          keywords[:ref] = keywords.delete(:schema) if keywords.key?(:schema)

          @schema = Schema.new(keywords)
        end

        # Returns true if content type is a JSON MIME type as specified by
        # https://mimesniff.spec.whatwg.org/#json-mime-type.
        def json_type?
          content_type.match?(JSON_TYPE)
        end

        # Returns true if content type is <code>"application/json-seq"</code>.
        def json_seq_type?
          content_type == JSON_SEQ_TYPE
        end

        # Returns a hash representing the \OpenAPI response object.
        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            if version == OpenAPI::V2_0
              {
                description: description,
                schema: schema.to_openapi(version),
                headers: headers.transform_values do |header|
                  header.to_openapi(version) unless header.reference?
                end.compact.presence,
                examples: (
                  if (example = examples.values.first).present?
                    { content_type => example.resolve(definitions).value }
                  end
                )
              }
            else
              {
                summary: (summary if version >= OpenAPI::V3_2),
                description: description,
                headers: headers.transform_values do |header|
                  header.to_openapi(version)
                end.presence,
                content: {
                  content_type => {
                    **if json_seq_type? && schema.array? && version >= OpenAPI::V3_2
                        { itemSchema: schema.items.to_openapi(version) }
                      else
                        { schema: schema.to_openapi(version) }
                      end,
                    examples: examples.transform_values(&:to_openapi).presence
                  }.compact
                },
                links: links.transform_values do |link|
                  link.to_openapi(version)
                end.presence
              }
            end
          )
        end
      end
    end
  end
end
