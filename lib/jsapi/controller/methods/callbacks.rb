# frozen_string_literal: true

require_relative 'callbacks/callback'
require_relative 'callbacks/class_methods'

module Jsapi
  module Controller
    module Methods
      module Callbacks
        def self.included(base) # :nodoc:
          base.extend(ClassMethods)
        end

        private

        def _api_callback(name, operation_name, ...)
          operation_name = operation_name.to_s

          self.class._api_callbacks(name).each do |callback|
            next if callback.skip_on?(self, operation_name)

            if (method_or_proc = callback.method_or_proc).respond_to?(:call)
              method_or_proc.call(...)
            else
              send(method_or_proc, ...)
            end
          end
          nil
        end

        def _api_before_rendering(operation_name, result, ...)
          operation_name = operation_name.to_s

          self.class._api_callbacks(:before_rendering).reduce(result) do |memo, callback|
            next memo if callback.skip_on?(self, operation_name)

            if (method_or_proc = callback.method_or_proc).respond_to?(:call)
              method_or_proc.call(memo, ...)
            else
              send(method_or_proc, memo, ...)
            end
          end
        end
      end
    end
  end
end
