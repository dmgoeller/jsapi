# frozen_string_literal: true

require_relative 'methods/callbacks'

module Jsapi
  module Controller
    module Methods
      def self.included(base) # :nodoc:
        base.include(Callbacks)
      end

      # Returns the Meta::Definitions instance associated with the controller class. In
      # particular, this method can be used to create an OpenAPI document, for example:
      #
      #   render(json: api_definitions.openapi_document)
      #
      def api_definitions
        self.class.api_definitions
      end

      ##
      # :method: api_operation
      # :args: operation_name = nil, omit: nil, status: nil, strong: false, &block
      #
      # Performs an API operation by calling the given block.
      #
      # The request parameters are passed as an instance of the operation's model class to the
      # block. Parameter names are converted to snake case.
      #
      # The object returned by the block is implicitly rendered or streamed according to the
      # most appropriate +response+ specification if the media type of that response is one of:
      #
      # - <code>"application/json"</code>, <code>"text/json"</code>, <code>"\*/\*+json"</code> -
      #   The \JSON representation of the object is rendered.
      # - <code>"application/json-seq"</code> - The object is streamed in \JSON sequence
      #   text format.
      # - <code>"text/plain"</code> - The +to_s+ representation of the object is rendered.
      #
      # Example:
      #
      #   api_operation('foo') do |api_params|
      #     # ...
      #   end
      #
      # +operation_name+ can be +nil+ if the controller handles one operation only.
      #
      # If +:strong+ is +true+, parameters that can be mapped are accepted only. That means
      # that the model passed to the block is invalid if there are any request parameters
      # that can't be mapped to a parameter or a request body property of the operation.
      #
      # The +:omit+ option specifies on which conditions properties are omitted in responses.
      # Possible values are:
      #
      # - +:empty+ - All of the  properties whose value is empty are omitted.
      # - +:nil+ - All of the properties whose value is +nil+ are omitted.
      #
      # Raises an +ArgumentError+ when +:omit+ is other than +:empty+, +:nil+ or +nil+.
      #
      # See Callbacks::ClassMethods for possible callbacks.

      ##
      # :method: api_operation!
      # :args: operation_name = nil, omit: nil, status: nil, strong: false, &block
      #
      # Like +api_operation+, except that a ParametersInvalid exception is raised
      # when request parameters are invalid.
      #
      #   api_operation!('foo') do |api_params|
      #     # ...
      #   end

      [true, false].each do |bang|
        define_method(bang ? :api_operation! : :api_operation) \
        do |operation_name = nil, omit: nil, status: nil, strong: false, &block|
          operation_model = _api_operation_model(operation_name)
          response_model = _api_response_model(operation_model, status)

          # Perform operation
          api_params = _api_params(operation_model, strong: strong)

          result = begin
            _api_before_processing(operation_name, api_params)
            raise ParametersInvalid.new(api_params) if bang && api_params.invalid?

            block&.call(api_params)
          rescue StandardError => e
            definitions = api_definitions

            # Lookup a rescue handler
            rescue_handler = definitions.rescue_handler_for(e)
            raise e if rescue_handler.nil?

            # Change the HTTP status code and response model
            status = rescue_handler.status
            response_model = operation_model.response(status)
            raise e if response_model.nil?

            # Call on_rescue callbacks
            definitions.on_rescue_callbacks.each do |callback|
              callback.respond_to?(:call) ? callback.call(e) : send(callback, e)
            end

            Error.new(e, status: status)
          end
          # Return if response body has already been rendered
          return if response_body

          # Produce response
          media_type, content_model = _api_media_type_and_content_model(response_model)
          result = _api_before_rendering(operation_name, result, api_params)

          api_response = Response.new(
            result,
            content_model,
            omit: omit,
            locale: response_model.locale
          )
          if media_type.json?
            render(json: api_response, status: status, content_type: media_type.to_s)
          elsif media_type == Media::Type::TEXT_PLAIN
            render(plain: result, status: status, content_type: media_type.to_s)
          elsif media_type == Media::Type::APPLICATION_JSON_SEQ
            self.content_type = media_type.to_s
            response.status = status

            response.stream.tap do |stream|
              api_response.write_json_seq_to(stream)
            ensure
              stream.close
            end
          end
        end
      end

      # Returns the request parameters as an instance of the operation's model class.
      # Parameter names are converted to snake case.
      #
      #   params = api_params('foo')
      #
      # +operation_name+ can be +nil+ if the controller handles one operation only.
      #
      # If +strong+ is +true+, parameters that can be mapped are accepted only. That means
      # that the model returned is invalid if there are any request parameters that can't be
      # mapped to a parameter or a request body property of the operation.
      #
      # Note that each call of +api_params+ returns a newly created instance.
      def api_params(operation_name = nil, strong: false)
        _api_params(_api_operation_model(operation_name), strong: strong)
      end

      # Returns a Response to serialize the JSON representation of +result+ according to the
      # appropriate +response+ specification.
      #
      #   render(json: api_response(bar, 'foo', status: 200))
      #
      # +operation_name+ can be +nil+ if the controller handles one operation only.
      #
      # The +:omit+ option specifies on which conditions properties are omitted.
      # Possible values are:
      #
      # - +:empty+ - All of the  properties whose value is empty are omitted.
      # - +:nil+ - All of the properties whose value is +nil+ are omitted.
      #
      # Raises an +ArgumentError+ when +:omit+ is other than +:empty+, +:nil+ or +nil+.
      def api_response(result, operation_name = nil, omit: nil, status: nil)
        operation_model = _api_operation_model(operation_name)
        response_model = _api_response_model(operation_model, status)

        Response.new(
          result,
          _api_media_type_and_content_model(response_model).second,
          omit: omit,
          locale: response_model.locale
        )
      end

      private

      def _api_media_type_and_content_model(response_model)
        response_model.media_type_and_content_for(
          *(request.headers['Accept']&.split(',').presence || [Media::Range::ALL])
        )
      end

      def _api_operation_model(operation_name)
        operation_model = api_definitions.find_operation(operation_name)
        return operation_model if operation_model

        raise "operation not defined: #{operation_name}"
      end

      def _api_params(operation_model, strong:)
        (operation_model.model || Model::Base).new(
          Parameters.new(
            params.except(:action, :controller, :format).permit!,
            request,
            operation_model,
            strong: strong
          )
        )
      end

      def _api_response_model(operation_model, status)
        response_model = operation_model.response(status)
        return response_model if response_model

        raise "status code not defined: #{status}"
      end
    end
  end
end
