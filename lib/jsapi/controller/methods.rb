# frozen_string_literal: true

require_relative 'methods/callbacks'

module Jsapi
  module Controller
    # Raised when no operation with the specified name could be found.
    class OperationNotFound < StandardError
      def initialize(operation_name)
        super("operation not found: #{operation_name}")
      end
    end

    # Raised when no suitable response could be found.
    class ResponseNotFound < StandardError
      def initialize(operation, status)
        super(
          if operation.responses.none?
            "#{operation.name.inspect} has no responses"
          else
            "#{operation.name.inspect} has no response for status #{status}"
          end
        )
      end
    end

    # Raised when the current request could not be authenticated.
    class Unauthorized < StandardError
      def initialize # :nodoc:
        super('request could not be authenticated')
      end
    end

    # Raised when the request parameters are invalid.
    class ParametersInvalid < StandardError

      # The parameters.
      attr_reader :params

      def initialize(params)
        @params = params
        super('')
      end

      # Returns the errors encountered.
      def errors
        @params.errors.errors
      end

      # Overrides <code>Exception#message</code> to lazily generate the error message.
      def message
        "#{@params.errors.full_messages.map { |m| m.delete_suffix('.') }.join('. ')}."
      end
    end

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
      # +operation_name+ can be omitted if the controller handles one operation only.
      #
      # If no operation could be found for +operation_name+, an OperationNotFound exception
      # is raised.
      #
      # +:status+ specifies the HTTP status code of the response to be produced.
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
      # Raises an Unauthorized exception if the Authentication module is included and the
      # current request could not be authenticated.
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
          operation = _api_operation(operation_name)
          response_model = nil

          result = begin
            # Authenticate request first if Authentication is included
            if respond_to?(:_api_authenticated?, true)
              raise Unauthorized unless _api_authenticated?(operation)

              _api_callback(:after_authentication, operation_name)
            end

            status = Status::Code.from(status)
            response_model = _api_response_model(operation, status)

            api_params = _api_params(operation, strong: strong)
            raise ParametersInvalid.new(api_params) if bang && api_params.invalid?

            _api_callback(:before_processing, operation_name, api_params)
            block&.call(api_params)
          rescue StandardError => e
            definitions = api_definitions

            # Lookup a rescue handler
            rescue_handler = definitions.rescue_handler_for(e)
            raise e if rescue_handler.nil?

            # Replace the status code and response model
            status = rescue_handler.status_code
            response_model = operation.find_response(status)
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
          status = status&.to_i
          return head(status) unless content_model

          result = _api_before_rendering(operation_name, result, api_params)

          api_response = Response.new(
            result,
            content_model,
            omit: omit,
            locale: response_model.locale
          )
          if media_type.json?
            render(
              json: api_response,
              status: status,
              content_type: media_type.to_s
            )
          elsif media_type == Media::Type::TEXT_PLAIN
            render(
              plain: result,
              status: status,
              content_type: media_type.to_s
            )
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
      # +operation_name+ can be omitted if the controller handles one operation only.
      #
      # If no operation could be found for +operation_name+, an OperationNotFound exception
      # is raised.
      #
      # If +strong+ is +true+, parameters that can be mapped are accepted only. That means
      # that the model returned is invalid if there are any request parameters that can't be
      # mapped to a parameter or a request body property of the operation.
      #
      # Note that each call of +api_params+ returns a newly created instance.
      def api_params(operation_name = nil, strong: false)
        _api_params(_api_operation(operation_name), strong: strong)
      end

      # Returns a Response to serialize the JSON representation of +result+ according to the
      # appropriate +response+ specification.
      #
      #   render(json: api_response(bar, 'foo', status: 200))
      #
      # +operation_name+ can be omitted if the controller handles one operation only.
      #
      # If no operation could be found for +operation_name+, an OperationNotFound exception
      # is raised.
      #
      # +:status+ specifies the HTTP status code of the response to be produced.
      #
      # The +:omit+ option specifies on which conditions properties are omitted.
      # Possible values are:
      #
      # - +:empty+ - All of the  properties whose value is empty are omitted.
      # - +:nil+ - All of the properties whose value is +nil+ are omitted.
      def api_response(result, operation_name = nil, omit: nil, status: nil)
        status = Status::Code.from(status)
        operation = _api_operation(operation_name)
        response_model = _api_response_model(operation, status)

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

      def _api_operation(operation_name)
        operation = api_definitions.find_operation(operation_name)
        return operation if operation

        raise OperationNotFound.new(operation_name)
      end

      def _api_params(operation, strong:)
        (operation.model || Model::Base).new(
          Parameters.new(
            params.except(:action, :controller, :format).permit!,
            request,
            operation,
            strong: strong
          )
        )
      end

      def _api_response_model(operation, status)
        response_model = operation.find_response(status)
        return response_model if response_model

        raise ResponseNotFound.new(operation, status)
      end
    end
  end
end
