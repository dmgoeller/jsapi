# frozen_string_literal: true

module Jsapi
  module Definition
    # Raised when a reference can't be resolved.
    class ReferenceError < StandardError
      def initialize(reference)
        super("reference can't be resolved: '#{reference}'")
      end
    end
  end
end
