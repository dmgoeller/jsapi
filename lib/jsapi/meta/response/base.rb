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
        # The alternative contents of the response. Maps instances of
        # Media::Range to Content objects.
        attribute :contents, { Media::Type => Content }, accessors: %i[reader writer]

        ##
        # :attr: description
        # The description of the response.
        attribute :description, String

        ##
        # :attr: headers
        # The headers of the response. Maps header names to Header objects or
        # references.
        attribute :headers, { String => Header }

        ##
        # :attr: links
        # The linked operations. Maps link names to Link objects.
        attribute :links, { String => Link }

        ##
        # :attr: locale
        # The locale to be used instead of the default locale when rendering
        # a response.
        attribute :locale, Symbol

        ##
        # :attr: nodoc
        # Prevents the response to be described in generated \OpenAPI documents.
        attribute :nodoc, values: [true, false], default: false

        ##
        # :attr: summary
        # The short description of the response.
        #
        # Applies to \OpenAPI 3.2 and higher.
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

        # Returns true if and only if +nodoc?+ returns true.
        def hidden?(*)
          nodoc?
        end

        # Returns a hash representing the \OpenAPI response object.
        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            if version == OpenAPI::V2_0
              media_type, content = contents.first
              example = content&.examples&.values&.first
              {
                description: description,
                schema: content&.schema&.to_openapi(version),
                headers:
                  headers.transform_values do |header|
                    header.to_openapi(version) unless header.reference?
                  end.compact.presence,
                examples:
                  if media_type.present? && example.present?
                    { media_type => example.resolve(definitions).value }
                  end
              }
            else
              {
                summary: (summary if version >= OpenAPI::V3_2),
                description: description,
                headers:
                  headers.transform_values do |header|
                    header.to_openapi(version)
                  end.presence,
                content:
                  contents.to_h do |nth_media_type, nth_content|
                    [nth_media_type, nth_content.to_openapi(version, nth_media_type)]
                  end.presence,
                links:
                  links.transform_values do |link|
                    link.to_openapi(version)
                  end.presence
              }
            end
          )
        end

        private

        def last_content
          contents.values.last || (add_content unless attributes_frozen?)
        end
      end
    end
  end
end
