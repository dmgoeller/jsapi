# frozen_string_literal: true

module Jsapi
  module JSON
    module TestHelper
      private

      def schema(definitions = nil, **keywords)
        definitions = Meta::Definitions.new if definitions.nil?

        Meta::Schema.wrap(
          Meta::Schema.new(**keywords).resolve(definitions),
          definitions
        )
      end
    end
  end
end
