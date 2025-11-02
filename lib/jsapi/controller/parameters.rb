# frozen_string_literal: true

require 'cgi'

module Jsapi
  module Controller
    # Used to wrap request parameters.
    class Parameters
      include Model::Nestable

      attr_reader :raw_additional_attributes, :raw_attributes

      # Creates a new instance that wraps +params+ according to +operation+. References are
      # resolved to API components in +definitions+.
      #
      # If +strong+ is true+ parameters that can be mapped are accepted only. That means that
      # the instance created is invalid if +params+ contains any parameters that can't be
      # mapped to a parameter or a request body property of +operation+.
      def initialize(params, request, operation, definitions, strong: false)
        params = params.to_h
        unassigned_params = params.dup

        @params_to_be_validated = strong == true ? params.dup : {}
        @raw_attributes = {}

        # Parameters
        operation.parameters.each do |name, parameter_model|
          parameter_model = parameter_model.resolve(definitions)

          @raw_attributes[name] = JSON.wrap(
            case parameter_model.in
            when 'header'
              request.headers[name]
            when 'querystring'
              query_params = request.query_parameters
              keys = query_params.keys

              unassigned_params.except!(*keys)
              @params_to_be_validated.except!(*keys)

              parameter_model.object? ? params.slice(*keys) : query_params.to_query
            else
              unassigned_params.delete(name)
            end,
            parameter_model.schema.resolve(definitions),
            definitions,
            context: :request
          )
        end

        # Request body
        request_body_schema = operation.request_body&.resolve(definitions)
                                       &.schema&.resolve(definitions)
        if request_body_schema&.object?
          request_body = JSON.wrap(
            unassigned_params,
            request_body_schema,
            definitions,
            context: :request
          )
          @raw_attributes.merge!(request_body.raw_attributes)
          @raw_additional_attributes = request_body.raw_additional_attributes
          @params_to_be_validated.except!(*@raw_additional_attributes.keys)
        else
          @raw_additional_attributes = {}
        end
      end

      # Validates the request parameters. Returns true if the parameters are valid, false
      # otherwise. Detected errors are added to +errors+.
      def validate(errors)
        validate_attributes(errors) &&
          validate_parameters(@params_to_be_validated, attributes, errors)
      end

      private

      def validate_parameters(params, attributes, errors, path = [])
        params.each.map do |key, value|
          if attributes.key?(key)
            # Validate nested parameters
            !value.respond_to?(:keys) || validate_parameters(
              value,
              attributes[key].try(:attributes) || {},
              errors,
              path + [key]
            )
          else
            errors.add(
              :base,
              I18n.translate(
                'jsapi.errors.forbidden',
                default: "'%<name>s' isn't allowed",
                name: path.empty? ? key : (path + [key]).join('.')
              )
            )
            false
          end
        end.all?
      end
    end
  end
end
