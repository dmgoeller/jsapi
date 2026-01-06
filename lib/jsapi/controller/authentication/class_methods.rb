# frozen_string_literal: true

module Jsapi
  module Controller
    module Authentication
      module ClassMethods
        ##
        # :call-seq:
        #   api_authenticate(*scheme_names, with:)
        #   api_authenticate(*scheme_names, &block)
        #
        # Registers a handler to authenticate requests according to the specified
        # security schemes.
        #
        #   api_authenticate 'basic_auth', with: :authenticate
        #
        # If no scheme names are specified, the handler is used as fallback for all
        # security schemes for which no handler is registered.
        #
        # The +:with+ option specifies the method to be called to authenticate
        # requests. Alternatively, a block can be given as handler.
        #
        # If the handler returns a truthy value, the request is assumed to be
        # authenticated successfully.
        #
        #   def authenticate(credentials)
        #     credentials.username == 'api_user' &&
        #       credentials.password == 'secret'
        #   end
        def api_authenticate(*scheme_names, with: nil, &block)
          handler = with || block
          raise ArgumentError, 'either the :with keyword argument or a block ' \
                               'must be specified' unless handler

          (scheme_names.presence || [nil]).each do |scheme_name|
            _api_authentication_handlers[scheme_name&.to_s] = handler
          end
        end

        def _api_authentication_handler(scheme_name) # :nodoc:
          scheme_name = scheme_name&.to_s

          _api_authentication_handlers[scheme_name] ||
            superclass.try(:_api_authentication_handler, scheme_name) ||
            (_api_authentication_handler(nil) unless scheme_name.nil?)
        end

        private

        def _api_authentication_handlers
          @_api_authentication_handlers ||= {}
        end
      end
    end
  end
end
