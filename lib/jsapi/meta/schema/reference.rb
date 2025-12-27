# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      # Refers a reusable schema.
      class Reference < Model::Reference
        ##
        # :attr: existence
        # The level of existence. The default is +ALLOW_OMITTED+.
        attribute :existence, Existence, default: Existence::ALLOW_OMITTED

        def resolve(definitions) # :nodoc:
          schema = super
          return schema if existence < Existence::ALLOW_EMPTY

          Delegator.new(schema, [existence, schema.existence].max)
        end

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
