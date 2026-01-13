# frozen_string_literal: true

module Jsapi
  module Meta
    module Response
      # Refers a reusable response.
      class Reference < Model::Reference
        ##
        # :attr: nodoc
        # Prevents the reference to be described in generated \OpenAPI documents.
        attribute :nodoc, values: [true, false], default: false

        # Returns true if and only if the reference or the resolved response
        # responds to +:nodoc?+ with true.
        def hidden?(definitions)
          return true if nodoc?

          resolve(definitions, deep: false).hidden?(definitions)
        end
      end
    end
  end
end
