# frozen_string_literal: true

module Jsapi
  module DSL
    class Operation < Node
      # Defines a parameter.
      def parameter(name, **options, &block)
        wrap_error "'#{name}'" do
          if options.any? || block.present?
            parameter_model = model.add_parameter(name, **options)
            Parameter.new(parameter_model).call(&block) if block.present?
          else
            model.add_parameter_reference(name)
          end
        end
      end

      # Defines the request body.
      def request_body(**options, &block)
        wrap_error 'request body' do
          model.request_body = Model::RequestBody.new(**options)
          RequestBody.new(model.request_body).call(&block) if block.present?
        end
      end

      # Defines a response. Default code is +default+.
      def response(code = nil, **options, &block)
        wrap_error 'response', code, code do
          response_model = model.add_response(code, **options)
          Response.new(response_model).call(&block) if block.present?
        end
      end
    end
  end
end
