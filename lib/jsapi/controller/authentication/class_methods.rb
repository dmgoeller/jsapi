# frozen_string_literal: true

module Jsapi
  module Controller
    module Authentication
      module ClassMethods
        ##
        # :call-seq:
        #   api_authenticate(scheme_name = nil, with:)
        #   api_authenticate(scheme_name = nil, &block)
        #
        # Registers a handler to authenticate requests according to the specified
        # security scheme.
        #
        #   api_authenticate 'basic_auth', with: :authenticate
        #
        # If +scheme_name+ is nil, the handler is used as fallback for all schemes
        # for which no handler is registered.
        #
        # The +:with+ option specifies the method to be called to authenticate
        # requests. Alternatively, a block can be given as handler.
        #
        # If the handler returns a truthy value, the request is assumed to be authenticated
        # successfully.
        #
        #   def authenticate(credentials)
        #     credentials.username == 'api_user' &&
        #       credentials.password == 'secret'
        #   end
        def api_authenticate(scheme_name = nil, with: nil, &block)
          handler = with || block
          raise ArgumentError, 'either the :with keyword argument or a block ' \
                               'must be specified' unless handler

          (@_api_authentication_handlers ||= {})[scheme_name&.to_s] = handler
        end

        def _api_authentication_handler(scheme_name) # :nodoc:
          scheme_name = scheme_name&.to_s

          @_api_authentication_handlers&.fetch(scheme_name, nil) ||
            superclass.try(:_api_authentication_handler, scheme_name) ||
            (_api_authentication_handler(nil) unless scheme_name.nil?)
        end
      end
    end
  end
end
