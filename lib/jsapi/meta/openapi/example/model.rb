# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      module Example
        class Model < Meta::Base::Model
          include Extensions

          ##
          # :attr: description
          # The optional description of the example.
          attribute :description, String

          ##
          # :attr: external
          # If true, +value+ is interpreted as a URI pointing to an external sample value.
          attribute :external, values: [true, false]

          ##
          # :attr: summary
          # The optional summary of the example.
          attribute :summary, String

          ##
          # :attr: value
          # The sample value.
          attribute :value

          # Returns a hash representing the \OpenAPI example object.
          def to_openapi(*)
            with_openapi_extensions(summary: summary, description: description).tap do |hash|
              if external?
                hash[:external_value] = value
              else
                hash[:value] = value
              end
            end
          end
        end
      end
    end
  end
end
