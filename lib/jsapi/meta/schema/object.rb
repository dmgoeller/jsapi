# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Object < Base
        ##
        # :attr: additional_properties
        # The AdditionalProperties.
        attribute :additional_properties, AdditionalProperties

        ##
        # :attr: all_of_references
        attribute :all_of_references, [Reference]

        alias :all_of= :all_of_references= # :nodoc:
        alias :add_all_of :add_all_of_reference

        ##
        # :attr: discriminator
        # The Discriminator.
        attribute :discriminator, Discriminator

        ##
        # :attr: model
        # The model class to access nested object parameters by. The default
        # model class is Jsapi::Model::Base.
        attribute :model, Class, default: Jsapi::Model::Base

        ##
        # :attr: properties
        # The properties.
        attribute :properties, { String => Property }, accessors: %i[reader writer]

        def add_property(name, keywords = {}) # :nodoc:
          try_modify_attribute!(:properties) do
            (@properties ||= {})[name.to_s] = Property.new(name, keywords)
          end
        end

        def resolve_properties(definitions, context: nil)
          properties = merge_properties(definitions, [])

          case context
          when :response
            properties.reject { |_k, v| v.write_only? }
          when :request
            properties.reject { |_k, v| v.read_only? }
          else
            properties
          end
        end

        def to_json_schema # :nodoc:
          super.merge(
            allOf: all_of_references.map(&:to_json_schema).presence,
            properties: properties.transform_values(&:to_json_schema),
            additionalProperties: additional_properties&.to_json_schema,
            required: properties.values.select(&:required?).map(&:name)
          ).compact
        end

        def to_openapi(version, *) # :nodoc:
          super.merge(
            allOf: all_of_references.map do |schema|
              schema.to_openapi(version)
            end.presence,
            discriminator: discriminator&.to_openapi(version),
            properties: properties.transform_values do |property|
              property.to_openapi(version)
            end,
            additionalProperties: additional_properties&.to_openapi(version),
            required: properties.values.select(&:required?).map(&:name)
          ).compact
        end

        class Wrapper < Schema::Wrapper
          def additional_properties
            AdditionalProperties.wrap(super, definitions)
          end

          def resolve_properties(context: nil)
            super(definitions, context: context).transform_values do |property|
              Property.wrap(property, definitions)
            end
          end

          # Resolves the schema within +context+.
          #
          # Raises a +RuntimeError+ when the schema couldn't be resolved.
          def resolve_schema(object, context: nil)
            return self if discriminator.nil?

            properties = resolve_properties(context: context)

            discriminating_property = properties[discriminator.property_name]
            if discriminating_property.nil?
              raise InvalidValueError.new(
                'discriminator property',
                discriminator.property_name,
                valid_values: properties.keys
              )
            end

            discriminating_value = discriminating_property.reader.call(object)
            if discriminating_value.nil?
              discriminating_value = discriminating_property.default_value(context: context)

              if discriminating_value.nil? && discriminator.default_mapping.nil?
                raise "discriminating value can't be nil"
              end
            end

            schema_name = discriminator.mapping(discriminating_value) || discriminating_value

            schema = definitions.find_schema(schema_name)
            if schema.nil?
              default_mapping = discriminator.default_mapping
              schema = definitions.find_schema(default_mapping) unless default_mapping.nil?

              if schema.nil?
                raise "inheriting schema couldn't be found: " \
                      "#{[schema_name, default_mapping].compact.map(&:inspect).join(' or ')}"
              end
            end

            Wrapper
              .new(schema.resolve(definitions), definitions)
              .resolve_schema(object, context: context)
          end
        end

        protected

        def merge_properties(definitions, path)
          return properties unless all_of_references.present?

          {}.tap do |properties|
            all_of_references.each do |reference|
              schema = reference.resolve(definitions)
              raise "circular reference: #{reference.ref}" if schema.in?(path)

              properties.merge!(schema.merge_properties(definitions, path + [self]))
            end
            properties.merge!(self.properties)
          end
        end
      end
    end
  end
end
