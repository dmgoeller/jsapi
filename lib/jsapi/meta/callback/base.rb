# frozen_string_literal: true

module Jsapi
  module Meta
    module Parameter; end
    class Operation < Model::Base; end

    module Callback
      # Specifies a callback. Applies to \OpenAPI 3.0 and higher.
      class Base < Model::Base
        # The set of operations that can be called backed.
        class Operations < Model::Base
          ##
          # :attr: description
          # The description that applies to all operations.
          attribute :description, String

          ##
          # :attr: operations
          # The operations. Maps strings to Operation objects.
          attribute :operations, { String => Operation }, accessors: %i[reader writer]

          ##
          # :attr: parameters
          # The parameters that apply for all operations. Maps parameter names
          # to Parameter objects or references.
          attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

          ##
          # :attr: summary
          # The short summary that applies to all operations.
          attribute :summary, String

          def add_operation(method = nil, keywords = {}) # :nodoc:
            try_modify_attribute!(:operations) do
              method, keywords = nil, method if method.is_a?(Hash)
              method = 'get' if method.nil?

              (@operations ||= {})[method] = Operation.new(nil, keywords.merge(method: method))
            end
          end

          def add_parameter(name, keywords = {}) # :nodoc:
            try_modify_attribute!(:parameters) do
              name = name.to_s

              (@parameters ||= {})[name] = Parameter.new(name, keywords)
            end
          end

          # Returns a hash representing the \OpenAPI path item object that describes
          # the operations.
          def to_openapi(version, definitions)
            OpenAPI::PathItem.new(
              operations.values,
              description: description,
              summary: summary,
              parameters: parameters
            ).to_openapi(version, definitions)
          end
        end

        ##
        # :attr: expressions
        attribute :expressions, { String => Operations }, accessors: %i[reader writer]

        # Adds an expression.
        #
        # Raises an +ArgumentError+ if +expression+ is blank.
        def add_expression(expression, keywords = {})
          try_modify_attribute!(:expressions) do
            raise ArgumentError, "expression can't be blank" if expression.blank?

            (@expressions ||= {})[expression.to_s] = Operations.new(keywords)
          end
        end

        # Returns a hash representing the \OpenAPI callback object.
        def to_openapi(version, definitions)
          expressions.transform_values do |operations|
            operations.to_openapi(version, definitions)
          end
        end
      end
    end
  end
end
