# frozen_string_literal: true

require 'base64'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          # \HTTP \Basic \Authentication credentials
          class Basic < Base
            ##
            # :attr: username
            # The decoded username.

            ##
            # :attr: password
            # The decoded password.

            attr_reader :username, :password

            def initialize(authorization)
              super
              @username, @password =
                Base64.decode64(auth_param).split(':') \
                if auth_scheme == 'Basic' && auth_param.present?
            end

            def well_formed? # :nodoc:
              username.present? && password.present?
            end
          end
        end
      end
    end
  end
end
