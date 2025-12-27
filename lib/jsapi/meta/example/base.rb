# frozen_string_literal: true

module Jsapi
  module Meta
    module Example
      # Specifies an example.
      class Base < Model::Base
        include OpenAPI::Extensions

        ##
        # :attr: description
        # The description of the example.
        attribute :description, String

        ##
        # :attr: external_value
        # The URI of an external sample value.
        attribute :external_value, String, accessors: %i[reader]

        ##
        # :attr: serialized_value
        # The serialized form of the sample value.
        attribute :serialized_value, accessors: %i[reader]

        ##
        # :attr: summary
        # The short summary of the example.
        attribute :summary, String

        ##
        # :attr: value
        # The sample value.
        attribute :value

        def external_value=(value) # :nodoc:
          try_modify_attribute!(:external_value) do
            raise 'external value and serialized value are mutually exclusive' \
            unless serialized_value.nil?

            @external_value = value
          end
        end

        def serialized_value=(value)  # :nodoc:
          try_modify_attribute!(:serialized_value) do
            raise 'external value and serialized value are mutually exclusive' \
            unless external_value.nil?

            @serialized_value = value
          end
        end

        # Returns a hash representing the \OpenAPI example object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          with_openapi_extensions(
            summary: summary,
            description: description,
            **if version < OpenAPI::V3_2
                { value: value }
              else
                {
                  dataValue: value,
                  serializedValue: serialized_value
                }
              end,
            externalValue: external_value
          )
        end
      end
    end
  end
end
