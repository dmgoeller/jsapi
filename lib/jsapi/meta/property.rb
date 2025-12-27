# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a property
    class Property < Model::Base
      include Model::Wrappable

      delegate_missing_to :schema

      ##
      # :attr_reader: name
      # The name of the property.
      attribute :name, accessors: %i[reader]

      ##
      # :attr: read_only
      attribute :read_only, values: [true, false]

      ##
      # :attr_reader: schema
      # The Schema of the parameter.
      attribute :schema, accessors: %i[reader]

      ##
      # :attr: source
      # The alternative Callable used to read property values.
      attribute :source, Callable

      ##
      # :attr: write_only
      attribute :write_only, values: [true, false]

      # Creates a new property.
      #
      # Raises an +ArgumentError+ if +name+ is blank.
      def initialize(name, keywords = {})
        raise ArgumentError, "property name can't be blank" if name.blank?

        @name = name.to_s

        keywords = keywords.dup
        super(keywords.extract!(:read_only, :source, :write_only))
        keywords[:ref] = keywords.delete(:schema) if keywords.key?(:schema)

        @schema = Schema.new(keywords)
      end

      # Returns the Callable used to read a property value. By default, a property value is
      # read by calling the method whose name matches the property name.
      def reader
        source || (@reader ||= Callable.from(name.underscore.to_sym))
      end

      # Returns true if the level of existence is greater than or equal to +ALLOW_NIL+,
      # false otherwise.
      def required?
        schema.existence >= Existence::ALLOW_NIL
      end

      # Returns a hash representing the \OpenAPI schema object.
      def to_openapi(version, *)
        version = OpenAPI::Version.from(version)

        schema.to_openapi(version).tap do |result|
          result[:readOnly] = true if read_only?
          result[:writeOnly] = true if write_only? && version.major > 2
        end
      end

      class Wrapper < Model::Wrapper
        delegate :additional_properties, :default_value, :items, to: :schema

        def schema
          @schema ||= Schema.wrap(super, definitions)
        end
      end
    end
  end
end
