# frozen_string_literal: true

module Jsapi
  module Meta
    module Parameter
      # Specifies a parameter.
      class Base < Model::Base
        include OpenAPI::Extensions

        delegate_missing_to :schema

        ##
        # :attr: content_type
        # The media type used to describe complex parameters in \OpenAPI 3.0 and higher.
        attribute :content_type, Media::Type

        ##
        # :attr: deprecated
        # Specifies whether the parameter is marked as deprecated.
        attribute :deprecated, values: [true, false]

        ##
        # :attr: description
        # The description of the parameter.
        attribute :description, String

        ##
        # :attr_reader: examples
        # The examples. Maps example names to Example objects or references.
        attribute :examples, { String => Example }, default_key: 'default'

        ##
        # :attr: in
        # The location of the parameter. Possible values are:
        #
        # - <code>"header"</code>
        # - <code>"path"</code>
        # - <code>"query"</code>
        # - <code>"querystring"</code>
        #
        # The default location is <code>"query"</code>.
        attribute :in, String, values: %w[header path query querystring], default: 'query'

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
          super(
            keywords.extract!(
              :content_type,
              :deprecated,
              :description,
              :examples,
              :in,
              :openapi_extensions
            )
          )
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

          openapi_parameter_object(
            name,
            schema.resolve(definitions),
            version,
            location: self.in,
            content_type: content_type ||
              (Media::Type::TEXT_PLAIN if self.in == 'querystring'),
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
          is_querystring = self.in == 'querystring'
          schema = self.schema.resolve(definitions)

          if schema.object? && (version < OpenAPI::V3_2 || !is_querystring)
            explode_parameter(
              is_querystring ? nil : name,
              schema,
              version,
              definitions,
              location: is_querystring ? 'query' : self.in,
              required: required?,
              deprecated: deprecated?
            )
          else
            [to_openapi(version, definitions)]
          end.compact
        end

        private

        def explode_parameter(name, schema, version, definitions, location:, required:, deprecated:)
          schema.resolve_properties(definitions, context: :request).values.flat_map do |property|
            property_schema = property.schema.resolve(definitions)
            parameter_name = name ? "#{name}[#{property.name}]" : property.name
            required = (required && property.required?).presence
            deprecated = (deprecated || property_schema.deprecated?).presence

            if property_schema.object?
              explode_parameter(
                parameter_name,
                property_schema,
                version,
                definitions,
                location: location,
                required: required,
                deprecated: deprecated
              )
            else
              [
                openapi_parameter_object(
                  parameter_name,
                  property_schema,
                  version,
                  location: location,
                  description: property_schema.description,
                  required: required,
                  deprecated: deprecated,
                  allow_empty_value: property.schema.existence <= Existence::ALLOW_EMPTY
                )
              ]
            end.compact
          end
        end

        def openapi_parameter_object(name, schema, version,
                                     allow_empty_value:,
                                     deprecated:,
                                     description:,
                                     location:,
                                     required:,
                                     content_type: nil,
                                     examples: nil)

          return if location == 'querystring' && version < OpenAPI::V3_2

          if schema.object? && version == OpenAPI::V2_0
            raise "OpenAPI 2.0 doesn't allow object parameters in #{location}"
          end

          name = "#{name}[]" if schema.array?

          with_openapi_extensions(
            name: name,
            in: location,
            description: description,
            required: required.presence,
            allowEmptyValue: allow_empty_value.presence,
            **if version == OpenAPI::V2_0
                {
                  collectionFormat: ('multi' if schema.array?),
                  **schema.to_openapi(version)
                }
              else
                openapi_schema = schema.to_openapi(version).except(:deprecated)

                openapi_examples = examples&.transform_values do |example|
                  example.to_openapi(version)
                end.presence
                {
                  deprecated: deprecated.presence,
                  **if content_type.blank?
                      # simple scenario
                      {
                        schema: openapi_schema,
                        examples: openapi_examples
                      }
                    else
                      # complex scenario
                      {
                        content: {
                          content_type => {
                            schema: openapi_schema,
                            examples: openapi_examples
                          }.compact
                        }
                      }
                    end
                }
              end
          )
        end
      end
    end
  end
end
