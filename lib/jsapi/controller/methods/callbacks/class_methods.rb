# frozen_string_literal: true

module Jsapi
  module Controller
    module Methods
      module Callbacks
        module ClassMethods
          # :call-seq:
          #   api_after_validation(method, except: nil, only: nil)
          #   api_after_validation(except: nil, only: nil, &block)
          #
          # Registers a callback that is triggered by +api_operation!+ after the
          # parameters have been validated successfully.
          #
          #   api_after_validation do |api_params|
          #     # ...
          #   end
          #
          # When calling an +api_after_validation+ callback, the parameters are
          # passed.
          def api_after_validation(method = nil, **options, &block)
            _api_add_callback(:after_validation, method, **options, &block)
          end

          # :call-seq:
          #   api_before_rendering(method, except: nil, only: nil)
          #   api_before_rendering(except: nil, only: nil, &block)
          #
          # Registers a callback that is triggered by +api_operation+ and
          # +api_operation!+ before the response body is rendered.
          #
          #   api_before_rendering do |result, api_params|
          #     { request_id: api_params.request_id, payload: result }
          #   end
          #
          # When calling an +api_before_rendering+ callback, the result and
          # parameters are passed. The value returned by the callback replaces
          # the result to be rendered.
          def api_before_rendering(method = nil, **options, &block)
            _api_add_callback(:before_rendering, method, **options, &block)
          end

          def _api_add_callback(kind, method = nil, **options, &block) # :nodoc:
            method_or_block = method || block
            raise ArgumentError, 'either a method or a block must be ' \
                                  'specified' unless method_or_block

            ((@_api_callbacks ||= {})[kind] ||= []) <<
              Callback.new(method_or_block, **options)
          end

          def _api_callbacks(kind) # :nodoc:
            callbacks = @_api_callbacks&.fetch(kind, nil) || []
            return callbacks unless superclass.respond_to?(:_api_callbacks)

            superclass._api_callbacks(kind) + callbacks
          end
        end
      end
    end
  end
end
