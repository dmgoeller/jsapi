# frozen_string_literal: true

module Jsapi
  module Definition
    module Example
      class Builder # :nodoc:
        def initialize(schema, api, locale: nil)
          @schema = Schema.wrap(schema, api)
          @locale = locale
        end

        def generate_json(object, omit: nil)
          raise ArgumentError, Support::Messages.invalid_value(
            name: 'omit',
            value: omit,
            valid_values: %i[empty nil]
          ) if [nil, :empty, :nil].exclude?(omit)

          with_locale { @schema.jsonify(object, omit: omit) }
        end

        private

        def with_locale(&block)
          if @locale
            I18n.with_locale(@locale, &block)
          else
            yield
          end
        end
      end
    end
  end
end
