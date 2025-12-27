# frozen_string_literal: true

module Jsapi
  module Meta
    module RequestBody
      # Specifies a request body.
      class Base < Model::Base
        include OpenAPI::Extensions

        # To still allow to specify content-related directives within blocks
        delegate_missing_to :last_content

        ##
        # :attr_reader: contents
        # The Media::Range and Content objects.
        attribute :contents, { Media::Range => Content }, accessors: %i[reader writer]

        ##
        # :attr: description
        # The description of the request body.
        attribute :description, String

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
          @default_media_range = @default_content = @sorted_contents = nil if name == :contents
          super
        end

        def add_content(media_range = nil, keywords = {}) # :nodoc:
          try_modify_attribute!(:contents) do
            media_range, keywords = nil, media_range if media_range.is_a?(Hash)
            media_range = Media::Range.from(media_range || Media::Range::APPLICATION_JSON)

            (@contents ||= {})[media_range] = Content.new(keywords)
          end
        end

        # Returns the most appropriate content for the given media type.
        def content_for(media_type)
          (@sorted_contents ||= contents.sort)
            .find { |media_range, _content| media_range =~ media_type }
            &.second || default_content
        end

        def default_content
          @default_content ||= contents.values.first
        end

        def default_media_range
          @default_media_range = contents.keys.first
        end

        def freeze_attributes # :nodoc:
          add_content if contents.blank?
          super
        end

        # Returns a hash representing the \OpenAPI parameter object.
        # Applies to \OpenAPI 2.0.
        def to_openapi_parameter
          schema = default_content.schema

          with_openapi_extensions(
            {
              name: 'body',
              in: 'body',
              description: description,
              required: schema.existence >= Existence::ALLOW_NIL,
              **schema.to_openapi(OpenAPI::V2_0)
            }
          )
        end

        # Returns a hash representing the \OpenAPI request body object.
        # Applies to \OpenAPI 3.0 and higher.
        def to_openapi(version, *)
          with_openapi_extensions(
            description: description,
            content: contents.transform_values do |content|
              content.to_openapi(version)
            end,
            required: contents.values.all? do |content|
              content.schema.existence >= Existence::ALLOW_NIL
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
