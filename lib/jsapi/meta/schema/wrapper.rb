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

        # Generates a JSON value representing +value+.
        def jsonify(value, context: nil, omit: nil)
          value = default_value(context: context) if value.nil?
          raise JsonifyError, "can't be nil" if value.nil? && !nullable?

          jsonify_value(value, context: context, omit: omit) unless value.nil?
        end

        private

        def jsonify_value(value, **)
          value
        end
      end
    end
  end
end
