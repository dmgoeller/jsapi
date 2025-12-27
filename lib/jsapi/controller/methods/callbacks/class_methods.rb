# frozen_string_literal: true

module Jsapi
  module Controller
    module Methods
      module Callbacks
        module ClassMethods
          ##
          # :method: api_before_processing
          # :call-seq:
          #   api_before_processing(method, except: nil, only: nil)
          #   api_before_processing(except: nil, only: nil, &block)
          #
          # Triggered by +api_operation+ and +api_operation!+ before the block is
          # performed.
          #
          #   api_before_processing do |api_params
          #     # ...
          #   end
          #
          # An +api_before_processing+ callback must be able to accept one positional
          # argument to receive the request parameters. The returned value is not
          # used in further processing.

          ##
          # :method: api_before_rendering
          # :call-seq:
          #   api_before_rendering(method, except: nil, only: nil)
          #   api_before_rendering(except: nil, only: nil, &block)
          #
          # Triggered by +api_operation+ and +api_operation!+ before the response body
          # is rendered.
          #
          #   api_before_rendering do |result, api_params|
          #     { request_id: api_params.request_id, payload: result }
          #   end
          #
          # An +api_before_rendering+ callback must be able to accept two positional
          # arguments to receive the result to be rendered as the first argument and
          # the request parameters as the second argument. Instead of the passed
          # result, the returned value is rendered.

          %i[before_processing before_rendering].each do |kind|
            define_method(:"api_#{kind}") do |method = nil, **options, &block|
              raise ArgumentError, 'neither method nor block is given' if !method && !block

              ((@_api_callbacks ||= {})[kind] ||= []) << Callback.new(method || block, **options)
            end
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
