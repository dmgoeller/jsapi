# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define a schema.
    class Schema < Base

      ##
      # :method: additional_properties
      # :args: **keywords, &block
      # Specifies the schema of properties that are not explicity specified.
      #
      #   additional_properties type: 'string'
      #
      # See Meta::Schema::Object#additional_properties for further information.

      # Includes all of the properties from +schemas+. Each argument must be the name of
      # a schema defined by ClassMethods#api_schema or Definitions#schema.
      def all_of(*schemas)
        schemas.each { |schema| @meta_model.add_all_of({ ref: schema }) }
      end

      ##
      # :method: conversion
      # :args: method_or_proc
      # Specifies the method or +Proc+ to convert values by.
      #
      #   conversion :upcase
      #
      #   conversion ->(value) { value.upcase }
      #
      # Raises an error if type is other than <code>"integer"</code>,
      # <code>"number"</code> or <code>"string"</code>.

      ##
      # :method: default
      # :args: value
      # Specifies the default value.

      ##
      # :method: deprecated
      # :args: arg
      # Specifies whether or not the schema is deprecated.
      #
      #   deprecated true

      ##
      # :method: description
      # :args: arg
      # Specifies the description of the schema.

      ##
      # :method: enum
      # :args: values
      # Specifies the allowed values.
      #
      #   enum %w[foo bar]

      ##
      # :method: external_docs
      # :args: **keywords, &block
      # Specifies the external documentation.
      #
      # See Meta::Schema::Base#external_docs for further information.

      # Adds a sample matching the schema.
      #
      #   example 'foo'
      def example(example)
        @meta_model.add_example(example)
      end

      ##
      # :method: existence
      # :args: level
      # Specifies the level of existence.
      #
      #   existence :allow_nil
      #
      # See Meta::Schema::Base#existence for further information.

      # Specifies the format of a string.
      #
      #   format 'date-time'
      #
      # Raises an Error if type is other than <code>"string"</code>.
      #
      # See Meta::Schema::String#format for further information.
      def format(format)
        keyword(:format, format)
      end

      # Defines the kind of items that can be contained in an array.
      #
      #   items do
      #     property 'foo', type: 'string'
      #   end
      #
      # Raises an Error if type is other than <code>"array"</code>.
      def items(**keywords, &block)
        unless @meta_model.respond_to?(:items=)
          raise Error, "items isn't supported for '#{@meta_model.type}'"
        end

        define do
          @meta_model.items = keywords

          @meta_model.items.tap do |items|
            Schema.new(items, &block) if block
          end
        end
      end

      ##
      # :method: max_items
      # :args: value
      # Specifies the maximum length of an array.
      #
      # Raises an Error if type is other than <code>"array"</code>.

      ##
      # :method: max_length
      # :args: value
      # Specifies the maximum length of a string.
      #
      # Raises an Error if type is other than <code>"string"</code>.

      ##
      # :method: maximum
      # :args: value_or_keywords
      # Specifies the maximum value of an integer or a number.
      #
      #   maximum 9
      #
      #   maximum value: 10, exclusive: true
      #
      # Raises an Error if type is other than <code>"integer"</code> or <code>"number"</code>.

      ##
      # :method: min_items
      # :args: value
      # Specifies the minimum length of an array.
      #
      # Raises an Error if type is other than <code>"array"</code>.

      ##
      # :method: min_length
      # :args: min_length
      # Specifies the minimum length of a string.
      #
      # Raises an Error if type is other than <code>"string"</code>.

      ##
      # :method: minimum
      # :args: value_or_keywords
      # Specifies the minimum value of an integer or a number.
      #
      #   minimum 1
      #
      #   minimum value: 0, exclusive: true
      #
      # Raises an Error if type is other than <code>"integer"</code> or <code>"number"</code>.

      # Defines the model class to access nested object parameters by.
      #
      #   model Foo do
      #     def bar
      #       # ...
      #     end
      #   end
      #
      # +klass+ can be any subclass of Model::Base. If block is given, an anonymous class
      # is created that inherits either from +klass+ or Model::Base.
      #
      # Raises an Error if type is other than <code>"object"</code>.
      def model(klass = nil, &block)
        unless @meta_model.respond_to?(:model=)
          raise Error, "model isn't supported for '#{@meta_model.type}'"
        end

        if block
          klass = Class.new(klass || Model::Base)
          klass.class_eval(&block)
        end
        @meta_model.model = klass
      end

      ##
      # :method: multiple_of
      # :args: value
      # Specifies the value an integer or a number must be a multiple of.
      #
      # Raises an Error if type is other than <code>"integer"</code> or <code>"number"</code>.

      ##
      # :method: pattern
      # :args: regex
      # Specifies the regular expression a string must match.
      #
      # Raises an Error if type is other than <code>"string"</code>.

      # Adds a property.
      #
      #   property 'foo', type: 'string'
      #
      #   property 'foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      #
      # Raises an Error if type is other than <code>"object"</code>.
      def property(name, **keywords, &block)
        define('property', name.inspect) do
          unless @meta_model.respond_to?(:add_property)
            raise Error, "property isn't supported for '#{@meta_model.type}'"
          end

          @meta_model.add_property(name, keywords).tap do |property_model|
            Schema.new(property_model, &block) if block
          end
        end
      end

      ##
      # :method: title
      # :args: arg
      # Specifies the title of the schema.
    end
  end
end
