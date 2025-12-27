# frozen_string_literal: true

require_relative 'json/value'
require_relative 'json/array'
require_relative 'json/boolean'
require_relative 'json/integer'
require_relative 'json/null'
require_relative 'json/number'
require_relative 'json/object'
require_relative 'json/string'

module Jsapi
  # Provides a DOM for JSON values.
  module JSON
    class << self
      def wrap(object, schema, context: nil)
        object = schema.default_value(context: context) if object.nil?
        return Null.new(schema) if object.nil?

        case schema.type
        when 'array'
          Array.new(object, schema, context: context)
        when 'boolean'
          Boolean.new(object, schema)
        when 'integer'
          Integer.new(object, schema)
        when 'number'
          Number.new(object, schema)
        when 'object'
          Object.new(object, schema, context: context)
        when 'string'
          String.new(object, schema)
        else
          raise "invalid type: #{schema.type}"
        end
      end
    end
  end
end
