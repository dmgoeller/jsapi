# frozen_string_literal: true

module Jsapi
  module Meta
    module Response
      # Refers a reusable response.
      class Reference < Model::Reference
        ##
        # :attr: locale
        # Overrides the locale of the referred response.
        attribute :locale, Symbol

        ##
        # :attr: nodoc
        # Prevents the reference to be described in generated \OpenAPI documents.
        attribute :nodoc, values: [true, false]
      end
    end
  end
end
