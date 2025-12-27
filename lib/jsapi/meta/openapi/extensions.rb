# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      module Extensions
        def self.included(base) # :nodoc:
          base.attribute :openapi_extensions, { String => String }
        end

        private

        def with_openapi_extensions(keywords = {})
          if openapi_extensions.present?
            keywords.merge!(
              openapi_extensions.transform_keys { |key| "x-#{key}" }
            )
          end
          keywords.compact!
          keywords
        end
      end
    end
  end
end
