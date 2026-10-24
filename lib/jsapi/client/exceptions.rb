# frozen_string_literal: true

module Jsapi
  module Client
    module Exceptions
      module ClassMethods
        # Registers +error_class+ to be raised when the server responds with a status code
        # matching +:on+.
        #
        # +error_class+ can be +StandardError+ or a subclass of it. +:on+ can be a status
        # code or a range of status codes.
        #
        #   class ServerError < StandardError; end
        #   class InternalServerError < ServerError; end
        #
        #   raises ServerError, on: '5xx'
        #   raises InternalServerError, on: '500'
        #
        # Raises an +ArgumentError+ if +error_class+ or +:on+ is invalid.
        def raises(error_class, on:)
          raise ArgumentError, "#{error_class.inspect} isn't a class" \
          unless error_class.is_a?(Class)

          raise ArgumentError, "#{error_class.inspect} isn't a subclass of StandardError" \
          unless error_class <= StandardError

          (@_raises ||= {})[Status.from(on)] = error_class
        end

        def error_class_for(status_code) # :nodoc:
          status_code = Status::Code.from(status_code)

          @_raises
            &.sort
            &.find { |status, _| status.match?(status_code) }
            &.second || superclass.try(:error_class_for, status_code)
        end
      end

      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end
    end
  end
end
