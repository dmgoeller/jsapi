# frozen_string_literal: true

module Jsapi
  module Meta
    module Response
      # Specifies a response.
      class Base < Model::Base
        include OpenAPI::Extensions

        # To still allow to specify content-related directives within blocks
        delegate_missing_to :last_content

        ##
        # :attr_reader: contents
        # The Media::Type and Content objects.
        attribute :contents, { Media::Type => Content }, accessors: %i[reader writer]

        ##
        # :attr: description
        # The description of the response.
        attribute :description, String

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
        # The locale to be used when rendering a response.
        attribute :locale, Symbol

        ##
        # :attr: nodoc
        # Prevents response to be described in generated \OpenAPI documents.
        attribute :nodoc, values: [true, false], default: false

        ##
        # :attr: summary
        # The short description of the response. Applies to \OpenAPI 3.2 and higher.
        attribute :summary, String

        def initialize(keywords = {})
          keywords = keywords.dup
          content_keywords = keywords.slice!(*self.class.attribute_names)

          # Move content-related keywords to :contents so that the first
          # key-value pair in @contents is created from them.
          if content_keywords.present?
            content_type = content_keywords.delete(:content_type)

            (keywords[:contents] ||= {}).reverse_merge!(
              { content_type => content_keywords }
            )
          end
          super(keywords)
        end

        def attribute_changed(name) # :nodoc:
          @default_media_type = nil if name == :contents
          super
        end

        def add_content(media_type = nil, keywords = {}) # :nodoc:
          try_modify_attribute!(:contents) do
            media_type, keywords = nil, media_type if media_type.is_a?(Hash)
            media_type = Media::Type.from(media_type || Media::Type::APPLICATION_JSON)

            (@contents ||= {})[media_type] = Content.new(keywords)
          end
        end

        def default_media_type
          @default_media_type ||= contents.keys.first
        end

        def freeze_attributes # :nodoc:
          add_content if contents.blank?
          super
        end

        # Returns the most appropriate media type and content for the given
        # media ranges.
        def media_type_and_content_for(*media_ranges)
          media_ranges
            .filter_map { |media_range| Media::Range.try_from(media_range) }
            .sort # e.g. "text/plain" before "text/*" before "*/*"
            .lazy.map do |media_range|
              contents.find do |media_type_and_content|
                media_range =~ media_type_and_content.first
              end
            end.first || contents.first
        end

        # Returns a hash representing the \OpenAPI response object.
        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            if version == OpenAPI::V2_0
              contents.first.then do |media_type, content|
                {
                  description: description,
                  schema: content.schema.to_openapi(version),
                  headers: headers.transform_values do |header|
                    header.to_openapi(version) unless header.reference?
                  end.compact.presence,
                  examples: (
                    if (example = content.examples.values.first).present?
                      { media_type => example.resolve(definitions).value }
                    end
                  )
                }
              end
            else
              {
                summary: (summary if version >= OpenAPI::V3_2),
                description: description,
                headers: headers.transform_values do |header|
                  header.to_openapi(version)
                end.presence,
                content: contents.to_h do |media_type, content|
                  [media_type, content.to_openapi(version, media_type)]
                end,
                links: links.transform_values do |link|
                  link.to_openapi(version)
                end.presence
              }
            end
          )
        end

        private

        def last_content
          contents.values.last || add_content
        end
      end
    end
  end
end
