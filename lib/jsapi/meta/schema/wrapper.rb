# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Wrapper < Model::Wrapper
        # The level of existence.
        attr_reader :existence

        def initialize(schema, definitions)
          @existence =
            [schema.existence].tap do |levels|
              s = schema
              while s.is_a?(Reference)
                s = s.resolve(definitions, deep: false)
                levels << s.existence
              end
            end.compact.max || Existence::ALLOW_OMITTED
          super
        end

        # Returns the default value within +context+.
        def default_value(context: nil)
          return default unless default.nil?

          definitions.default_value(type, context: context)
        end
      end
    end
  end
end
