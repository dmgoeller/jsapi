# frozen_string_literal: true

module Jsapi
  module Controller
    module Actions
      module ClassMethods
        ##
        # :method: api_action
        # :call-seq:
        #   api_action(name, operation_name = nil, action: :index, **options)
        #   api_action(operation_name = nil, action: :index, **options, &block)
        #
        # Defines a controller action that performs an API operation by wrapping
        # the given method or block by +api_operation+.
        #
        #   # Invoke :foo to perform :bar
        #   api_action :foo, :bar
        #
        #   # Call the given block to perform :bar
        #   api_action :bar do |api_params|
        #     # ...
        #   end
        #
        # Raises an +ArgumentError+ when neither +name+ nor +block+ is given.
        #
        # +:action+ specifies the name of the controller action to be defined.
        # The default is +:index+.
        #
        # All other options are passed to +api_operation+.

        ##
        # :method: api_action!
        # :call-seq:
        #   api_action!(name, operation_name = nil, action: :index, **options)
        #   api_action!(operation_name = nil, action: :index, **options, &block)
        #
        # Like +api_action+, except that +api_operation!+ is used instead of
        # +api_operation+.

        ['', '!'].each do |suffix|
          method = :"api_operation#{suffix}"

          define_method(:"api_action#{suffix}") \
          do |name = nil, operation_name = nil, action: nil, **options, &block|
            raise ArgumentError, 'neither name nor block is given' if !name && !block

            operation_name = name if operation_name.nil?

            define_method(action || :index, &(
              if block
                -> { send(method, operation_name, **options, &block) }
              else
                -> { send(method, operation_name, **options) { |p| send(name, p) } }
              end
            ))
          end
        end
      end
    end
  end
end
