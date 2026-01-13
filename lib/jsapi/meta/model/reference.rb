# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      # The base reference class.
      class Reference < Base
        # Derrives the component type from the inner most module name.
        def self.component_type
          @component_type ||= name.split('::')[-2].underscore
        end

        # Derrives the \OpenAPI component type from the inner most module name.
        def self.openapi_component_type
          @openapi_component_type ||= name.split('::')[-2].pluralize.camelize(:lower)
        end

        ##
        # :attr: description
        # The description to be displayed instead of the description of the referred object.
        # Applies to \OpenAPI 3.1 and higher.
        attribute :description, String

        ##
        # :attr: ref
        # The name of the referred object.
        attribute :ref, String

        ##
        # :attr: summary
        # The summary to be displayed instead of the summary of the referred object.
        # Applies to \OpenAPI 3.1 and higher.
        attribute :summary, String

        # Returns true.
        def reference?
          true
        end

        # Resolves +ref+ by looking up the object with that name in +definitions+.
        #
        # Raises a ReferenceError if +ref+ could not be resolved.
        def resolve(definitions, deep: true)
          object = definitions.send("find_#{self.class.component_type}", ref)
          raise ReferenceError, ref if object.nil?

          deep ? object.resolve(definitions, deep: true) : object
        end

        # Returns a hash representing the \OpenAPI reference object.
        def to_openapi(version, *)
          version = OpenAPI::Version.from(version)

          { '$ref': "#/#{openapi_components_path(version)}/#{ref}" }.tap do |result|
            if version >= OpenAPI::V3_1
              result[:summary] = summary if summary
              result[:description] = description if description
            end
          end
        end

        private

        def openapi_components_path(version)
          component_type = self.class.openapi_component_type

          version.major == 2 ? component_type : "components/#{component_type}"
        end
      end
    end
  end
end
