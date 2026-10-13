# frozen_string_literal: true

module Jsapi
  module Client
    module TestHelper
      private

      def response_definition(**keywords)
        Meta::Response::Wrapper.new(
          Meta::Response.new(**keywords),
          Meta::Definitions.new
        )
      end

      def schema(**keywords)
        Meta::Schema.wrap(
          Meta::Schema.new(**keywords),
          Meta::Definitions.new
        )
      end
    end
  end
end
