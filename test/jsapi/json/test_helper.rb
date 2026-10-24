# frozen_string_literal: true

module Jsapi
  module JSON
    module TestHelper
      private

      def schema(api_definition = nil, **keywords)
        api_definition = Definition::API.new if api_definition.nil?

        Definition::Schema.wrap(
          Definition::Schema.new(**keywords).resolve(api_definition),
          api_definition
        )
      end
    end
  end
end
