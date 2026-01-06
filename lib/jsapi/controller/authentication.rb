# frozen_string_literal: true

require_relative 'authentication/credentials'
require_relative 'authentication/class_methods'

module Jsapi
  module Controller
    # The \Authentication add-on.
    #
    #   class FooController < Jsapi::Controller::Base
    #     include Jsapi::Controller::Authentication
    #
    #     api_authenticate 'basic_auth' do |credentials|
    #       # Implement authentication handler here
    #     end
    #
    #     api_security_scheme 'basic_auth', type: 'http', scheme: 'basic'
    #
    #     api_security_requirement do
    #       scheme 'basic_auth'
    #     end
    #   end
    module Authentication
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end

      # Returns true if and only if the current request satisfies at least one of
      # the security requirements applied to the specified operation. A security
      # requirement is satisfied if it is empty ({}) or all of the referred
      # security schemes are satisfied.
      #
      # +operation_name+ can be omitted if the controller handles one operation only.
      # If the operation isn't defined, an OperationNotDefined exception is raised.
      def api_authenticated?(operation_name = nil)
        _api_authenticated?(_api_operation(operation_name))
      end

      private

      def _api_authenticated?(operation)
        security_requirements = operation.security_requirements
        return true if security_requirements.blank?

        security_requirements.any? do |security_requirement|
          security_requirement.schemes.keys.all? do |scheme_name|
            # Find the most appropriate authentication handler
            authentication_handler = self.class._api_authentication_handler(scheme_name)
            next false unless authentication_handler

            # Find the appropriate security scheme
            security_scheme = api_definitions.find_security_scheme(scheme_name)
            next false unless security_scheme

            # Create the credentials to be passed to the authenticator
            credentials = Credentials.create(request, security_scheme)
            next false unless credentials&.well_formed?

            # Call authentication handler
            if authentication_handler.respond_to?(:call)
              authentication_handler.call(credentials)
            else
              send(authentication_handler, credentials)
            end
          end
        end
      end
    end
  end
end
