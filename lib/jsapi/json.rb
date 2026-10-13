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
      def wrap(value, schema, context: nil)
        value = schema.default_value(context: context) if value.nil?
        return Null.new(schema) if value.nil?

        case schema.type
        when 'array'
          Array.new(value, schema, context: context)
        when 'boolean'
          Boolean.new(value, schema)
        when 'integer'
          Integer.new(value, schema)
        when 'number'
          Number.new(value, schema)
        when 'object'
          Object.new(value, schema, context: context)
        when 'string'
          String.new(value, schema)
        else
          raise "invalid type: #{schema.type}"
        end
      end
    end
  end
end
