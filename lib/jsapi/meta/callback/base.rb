# frozen_string_literal: true

module Jsapi
  module Meta
    class Operation < Model::Base; end

    module Callback
      # Specifies a callback. Applies to \OpenAPI 3.0 and higher.
      class Base < Model::Base
        ##
        # :attr: operations
        attribute :operations, { String => Operation }, accessors: %i[reader writer]

        # Adds a callback operation.
        #
        # Raises an +ArgumentError+ if +expression+ is blank.
        def add_operation(expression, keywords = {})
          raise ArgumentError, "expression can't be blank" if expression.blank?

          (@operations ||= {})[expression.to_s] = Operation.new(nil, keywords)
        end

        # Returns a hash representing the \OpenAPI callback object.
        def to_openapi(version, definitions)
          operations.transform_values do |operation|
            OpenAPI::PathItem.new([operation]).to_openapi(version, definitions)
          end
        end
      end
    end
  end
end
