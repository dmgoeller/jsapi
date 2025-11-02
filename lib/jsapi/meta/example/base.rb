# frozen_string_literal: true

module Jsapi
  module Meta
    module Example
      # Specifies an example.
      class Base < Model::Base
        include OpenAPI::Extensions

        ##
        # :attr: description
        # The description of the example.
        attribute :description, String

        ##
        # :attr: external
        # If true, +value+ is interpreted as a URI pointing to an external sample value.
        attribute :external, values: [true, false]

        ##
        # :attr: summary
        # The summary of the example.
        attribute :summary, String

        ##
        # :attr: value
        # The sample value.
        attribute :value

        # Returns a hash representing the \OpenAPI example object.
        def to_openapi(*)
          with_openapi_extensions(
            { summary: summary, description: description }.tap do |result|
              result[external? ? :externalValue : :value] = value
            end
          )
        end
      end
    end
  end
end
