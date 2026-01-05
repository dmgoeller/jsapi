# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      TYPES = %w[array boolean integer number object string].freeze # :nodoc:

      class Base < Model::Base
        include OpenAPI::Extensions

        ##
        # :attr: default
        # The default value.
        attribute :default

        ##
        # :attr: deprecated
        # Specifies whether the schema is marked as deprecated.
        attribute :deprecated, values: [true, false]

        ##
        # :attr: description
        # The description of the schema.
        attribute :description, ::String

        ##
        # :attr: enum
        # The allowed values.
        attribute :enum, accessors: %i[reader]

        ##
        # :attr: examples
        # The samples matching the schema.
        attribute :examples, []

        ##
        # :attr: external_docs
        # The ExternalDocumentation object.
        attribute :external_docs, ExternalDocumentation

        ##
        # :attr: existence
        # The level of Existence. The default level of existence is +ALLOW_OMITTED+.
        attribute :existence, Existence, default: Existence::ALLOW_OMITTED

        ##
        # :attr: title
        # The title of the schema.
        attribute :title, String

        ##
        # :attr_reader: type
        # The type of the schema as a string.

        # The validations.
        attr_reader :validations

        # Creates a new schema.
        def initialize(keywords = {})
          keywords = keywords.dup
          add_example(keywords.delete(:example)) if keywords.key?(:example)

          @type = keywords.delete(:type)
          @validations = {}
          super(keywords)
        end

        TYPES.each do |type|
          define_method(:"#{type}?") { self.type == type }
        end

        def enum=(value) # :nodoc:
          try_modify_attribute!(:enum) do
            add_validation('enum', Validation::Enum.new(value))
            @enum = value
          end
        end

        # Returns true if and only if values can be +null+ as specified by \JSON \Schema.
        def nullable?
          existence <= Existence::ALLOW_NIL
        end

        # Returns true if and only if values can be omitted.
        def omittable?
          existence <= Existence::ALLOW_OMITTED
        end

        # Returns a hash representing the \JSON \Schema object.
        def to_json_schema
          {
            type: nullable? ? [type, 'null'] : type,
            title: title,
            description: description,
            default: default,
            examples: examples.presence,
            deprecated: deprecated?.presence
          }.tap do |result|
            validations.each_value do |validation|
              result.merge!(validation.to_json_schema_validation)
            end
          end.compact
        end

        # Returns a hash representing the \OpenAPI schema object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            if version.major == 2
              # OpenAPI 2.0
              {
                type: type,
                example: examples.first
              }
            elsif version.minor.zero?
              # OpenAPI 3.0
              {
                type: type,
                nullable: nullable?.presence,
                examples: examples.presence,
                deprecated: deprecated?.presence
              }
            else
              # OpenAPI 3.1 and higher
              {
                type: nullable? ? [type, 'null'] : type,
                examples: examples.presence,
                deprecated: deprecated?.presence
              }
            end.tap do |result|
              result[:title] = title
              result[:description] = description
              result[:default] = default
              result[:externalDocs] = external_docs&.to_openapi

              validations.each_value do |validation|
                result.merge!(validation.to_openapi_validation(version))
              end
            end
          )
        end

        def type # :nodoc:
          @type ||= self.class.name.demodulize.downcase
        end

        private

        def add_validation(keyword, validation)
          validations[keyword] = validation
        end
      end
    end
  end
end
