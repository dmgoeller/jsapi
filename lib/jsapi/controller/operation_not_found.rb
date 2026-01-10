# frozen_string_literal: true

module Jsapi
  module Controller
    # Raised when no operation with the specified name could be found.
    class OperationNotFound < StandardError
      def initialize(operation_name)
        super("operation not found: #{operation_name}")
      end
    end
  end
end
