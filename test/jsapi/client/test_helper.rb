# frozen_string_literal: true

module Jsapi
  module Client
    module TestHelper
      private

      def response_definition(**keywords)
        Definition::Response::Wrapper.new(
          Definition::Response.new(**keywords),
          Definition::API.new
        )
      end

      def schema_definition(**keywords)
        Definition::Schema.wrap(
          Definition::Schema.new(**keywords),
          Definition::API.new
        )
      end
    end
  end
end
