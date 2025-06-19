# frozen_string_literal: true

module Jsapi
  module Meta
    module Parameter
      # Specifies a parameter.
      class Base < Model::Base
        include OpenAPI::Extensions

        delegate_missing_to :schema

        ##
        # :attr: deprecated
        # Specifies whether or not the parameter is deprecated.
        attribute :deprecated, values: [true, false]

        ##
        # :attr: description
        # The description of the parameter.
        attribute :description, String

        ##
        # :attr_reader: examples
        # The examples.
        attribute :examples, { String => Example }, default_key: 'default'

        ##
        # :attr: in
        # The location of the parameter. Possible values are:
        #
        # - <code>"header"</code>
        # - <code>"path"</code>
        # - <code>"query"</code>
        #
        # The default location is <code>"query"</code>.
        attribute :in, String, values: %w[header path query], default: 'query'

        ##
        # :attr_reader: name
        # The name of the parameter.
        attribute :name, accessors: %i[reader]

        ##
        # :attr_reader: schema
        # The Schema of the parameter.
        attribute :schema, accessors: %i[reader]

        # Creates a new parameter.
        #
        # Raises an +ArgumentError+ if +name+ is blank.
        def initialize(name, keywords = {})
          raise ArgumentError, "parameter name can't be blank" if name.blank?

          @name = name.to_s

          keywords = keywords.dup
          super(keywords.extract!(:deprecated, :description, :examples, :in, :openapi_extensions))

          add_example(value: keywords.delete(:example)) if keywords.key?(:example)
          keywords[:ref] = keywords.delete(:schema) if keywords.key?(:schema)

          @schema = Schema.new(keywords)
        end

        # Returns true if empty values are allowed as specified by \OpenAPI, false otherwise.
        def allow_empty_value?
          schema.existence <= Existence::ALLOW_EMPTY && self.in == 'query'
        end

        # Returns true if it is required as specified by \JSON \Schema, false otherwise.
        def required?
          schema.existence > Existence::ALLOW_OMITTED || self.in == 'path'
        end

        # Returns a hash representing the \OpenAPI parameter object.
        def to_openapi(version, definitions)
          version = OpenAPI::Version.from(version)
          schema = self.schema.resolve(definitions)

          openapi_parameter(
            name,
            schema,
            version,
            description: description,
            required: required?,
            deprecated: deprecated?,
            allow_empty_value: allow_empty_value?,
            examples: examples
          )
        end

        # Returns an array of hashes representing the \OpenAPI parameter objects.
        def to_openapi_parameters(version, definitions)
          version = OpenAPI::Version.from(version)
          schema = self.schema.resolve(definitions)

          if schema.object?
            explode_parameter(
              name,
              schema,
              version,
              definitions,
              required: required?,
              deprecated: deprecated?
            )
          else
            [
              openapi_parameter(
                name,
                schema,
                version,
                description: description,
                required: required?,
                deprecated: deprecated?,
                allow_empty_value: allow_empty_value?,
                examples: examples
              )
            ]
          end
        end

        private

        def explode_parameter(name, schema, version, definitions, required:, deprecated:)
          schema.resolve_properties(definitions, context: :request).values.flat_map do |property|
            property_schema = property.schema.resolve(definitions)
            parameter_name = "#{name}[#{property.name}]"
            required = (required && property.required?).presence
            deprecated = (deprecated || property_schema.deprecated?).presence

            if property_schema.object?
              explode_parameter(
                parameter_name,
                property_schema,
                version,
                definitions,
                required: required,
                deprecated: deprecated
              )
            else
              [
                openapi_parameter(
                  parameter_name,
                  property_schema,
                  version,
                  description: property_schema.description,
                  required: required,
                  deprecated: deprecated,
                  allow_empty_value: property.schema.existence <= Existence::ALLOW_EMPTY
                )
              ]
            end
          end
        end

        def openapi_parameter(name, schema, version,
                              allow_empty_value:,
                              deprecated:,
                              description:,
                              required:,
                              examples: nil)

          name = schema.array? ? "#{name}[]" : name

          with_openapi_extensions(
            if version.major == 2
              raise "OpenAPI 2.0 doesn't allow object parameters " \
                    "in #{self.in}" if schema.object?

              {
                name: name,
                in: self.in,
                description: description,
                required: required.presence,
                allowEmptyValue: allow_empty_value.presence,
                collectionFormat: ('multi' if schema.array?)
              }.merge(schema.to_openapi(version))
            else
              {
                name: name,
                in: self.in,
                description: description,
                required: required.presence,
                allowEmptyValue: allow_empty_value.presence,
                deprecated: deprecated.presence,
                schema: schema.to_openapi(version).except(:deprecated),
                examples: examples&.transform_values(&:to_openapi).presence

                # NOTE: collectionFormat is replaced by 'style' and 'explode'.
                #       The default values are equal to 'multi'.
              }
            end
          )
        end
      end
    end
  end
end
