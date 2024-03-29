# frozen_string_literal: true

module Jsapi
  module Meta
    class Property
      attr_accessor :name, :source
      attr_reader :schema
      attr_writer :deprecated

      delegate :to_json_schema, :to_openapi_schema, to: :schema

      def initialize(name, **options)
        raise ArgumentError, "property name can't be blank" if name.blank?

        @name = name.to_s
        @deprecated = options[:deprecated] == true
        @source = options[:source]
        @schema = Schema.new(**options.except(:deprecated, :source))
      end

      def deprecated?
        @deprecated == true
      end

      def required?
        schema.existence > Existence::ALLOW_OMITTED
      end
    end
  end
end
