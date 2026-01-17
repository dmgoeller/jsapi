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

        def _api_callback(name, operation_name, *args)
          operation_name = operation_name.to_s

          self.class._api_callbacks(name).each do |callback|
            next if callback.skip_on?(self, operation_name)

            _api_exec(callback.method_or_proc, operation_name, *args)
          end
          nil
        end

        def _api_before_rendering(operation_name, result, *args)
          operation_name = operation_name.to_s
          args = [args, operation_name].flatten

          self.class._api_callbacks(:before_rendering).reduce(result) do |memo, callback|
            next memo if callback.skip_on?(self, operation_name)

            _api_exec(callback.method_or_proc, memo, operation_name, *args)
          end
        end

        def _api_exec(method_or_proc, *args)
          if method_or_proc.is_a?(Proc)
            arity = method_or_proc.arity
            args = args.take(arity) if arity < args.count

            instance_exec(*args, &method_or_proc)
          else
            arity = self.class.instance_method(method_or_proc).arity
            args = args.take(arity) if arity < args.count

            send(method_or_proc, *args)
          end
        end
      end
    end
  end
end
