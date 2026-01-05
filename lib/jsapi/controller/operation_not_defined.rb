# frozen_string_literal: true

module Jsapi
  module Controller
    # Raised by a controller method when the operation isn't defined.
    class OperationNotDefined < StandardError
      def initialize(operation_name)
        super("operation not defined: #{operation_name}")
      end
    end
  end
end
