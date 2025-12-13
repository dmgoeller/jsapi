# frozen_string_literal: true

module Jsapi
  module Controller
    module Methods
      module Callbacks
        class Callback
          # The method or +Proc+ to be performed.
          attr_reader :method_or_proc

          def initialize(method_or_proc, except: nil, only: nil)
            @method_or_proc = method_or_proc
            @except = Array.wrap(except).map(&:to_s) if except
            @only = Array.wrap(only).map(&:to_s) if only
          end

          # Returns true if the callback must not be triggered on +operation_name+.
          def skip_on?(operation_name)
            operation_name = operation_name.to_s
            @only&.exclude?(operation_name) || @except&.include?(operation_name) || false
          end
        end
      end
    end
  end
end
