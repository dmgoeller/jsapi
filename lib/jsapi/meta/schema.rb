# frozen_string_literal: true

require_relative 'schema/additional_properties'
require_relative 'schema/conversion'
require_relative 'schema/boundary'
require_relative 'schema/discriminator'
require_relative 'schema/reference'
require_relative 'schema/validation'

require_relative 'schema/base'
require_relative 'schema/wrapper'
require_relative 'schema/array'
require_relative 'schema/boolean'
require_relative 'schema/numeric'
require_relative 'schema/integer'
require_relative 'schema/number'
require_relative 'schema/object'
require_relative 'schema/string'

module Jsapi
  module Meta
    module Schema
      class << self
        # Creates a new schema. The +:type+ keyword determines the type of the schema to be
        # created. Possible types are:
        #
        # - <code>"array"</code>
        # - <code>"boolean"</code>
        # - <code>"integer"</code>
        # - <code>"number"</code>
        # - <code>"object"</code>
        # - <code>"string"</code>
        #
        # The default type is <code>"object"</code>.
        #
        # Raises an ArgumentError if the given type is invalid.
        def new(keywords = {})
          return Reference.new(keywords) if keywords.key?(:ref)

          type = keywords[:type]
          case type&.to_s
          when 'array'
            Array
          when 'boolean'
            Boolean
          when 'integer'
            Integer
          when 'number'
            Number
          when 'object', nil
            Object
          when 'string'
            String
          else
            raise ArgumentError, Messages.invalid_value(
              name: 'type',
              value: type,
              valid_values: TYPES
            )
          end.new(keywords.except(:type))
        end

        # Wraps +schema+.
        def wrap(schema, definitions)
          return if schema.nil?
          return schema if schema.is_a?(Wrapper)

          case schema.resolve(definitions).type
          when 'array'
            Array::Wrapper
          when 'object'
            Object::Wrapper
          else
            Wrapper
          end.new(schema, definitions)
        end
      end
    end
  end
end
