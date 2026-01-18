# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      # Refers a reusable schema.
      class Reference < Model::Reference
        ##
        # :attr: existence
        # Overrides the level of existence of the referred schema.
        attribute :existence, Existence, default: Existence::ALLOW_OMITTED

        # Returns a hash representing the \JSON \Schema reference object.
        def to_json_schema
          { '$ref': "#/definitions/#{ref}" }
        end

        private

        # Overrides Model::Reference#openapi_components_path.
        def openapi_components_path(version)
          version.major == 2 ? 'definitions' : super
        end
      end
    end
  end
end
