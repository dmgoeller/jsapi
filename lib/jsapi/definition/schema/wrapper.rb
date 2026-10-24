# frozen_string_literal: true

module Jsapi
  module Definition
    module Schema
      # Raised when jsonifying an object fails.
      class JsonifyError < RuntimeError
        attr_reader :path # :nodoc:

        def message
          [@path&.delete_prefix('.'), super].compact.join(' ')
        end

        def prepend(origin) # :nodoc:
          @path = "#{origin}#{@path}"
          self
        end
      end

      class Wrapper < Model::Wrapper
        # The level of existence.
        attr_reader :existence

        def initialize(schema, api)
          @existence =
            [schema.existence].tap do |levels|
              s = schema
              while s.is_a?(Reference)
                s = s.resolve(api, deep: false)
                levels << s.existence
              end
            end.compact.max || Existence::ALLOW_OMITTED
          super
        end

        # Returns the default value within +context+.
        def default_value(context: nil)
          return default unless default.nil?

          api.default_value(type, context: context)
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
