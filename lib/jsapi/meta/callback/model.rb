# frozen_string_literal: true

module Jsapi
  module Meta
    class Operation < Base::Model; end

    module Callback
      # Specifies a callback object. Applies to \OpenAPI 3.0 and higher.
      class Model < Base::Model
        ##
        # :attr: operations
        attribute :operations, { String => Operation }

        undef add_operation

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
            { operation.method => operation.to_openapi(version, definitions) }
          end
        end
      end
    end
  end
end
