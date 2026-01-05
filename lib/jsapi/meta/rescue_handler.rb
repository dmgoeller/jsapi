# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a rescue handler.
    class RescueHandler < Model::Base
      ##
      # :attr: error_class
      # The error class to be rescued.
      attribute :error_class, default: StandardError, accessors: %i[reader]

      ##
      # :attr: status_code
      # The Status::Code replacing the original status code when rescuing an
      # instance of error_class.
      attribute :status_code, Status::Code

      def error_class=(klass) # :nodoc:
        raise ArgumentError, "#{klass.inspect} isn't a class" \
        unless klass.is_a?(Class)

        raise ArgumentError, "#{klass.inspect} isn't a rescuable class" \
        unless klass <= StandardError

        @error_class = klass
      end

      # Returns true if +error+ is an instance of error_class.
      def match?(error)
        error.is_a?(error_class)
      end
    end
  end
end
