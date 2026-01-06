# frozen_string_literal: true

require 'base64'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          # Holds a username and password passed according to \HTTP
          # \Basic \Authentication.
          class Basic < Base
            # The decoded password.
            attr_reader :password

            # The decoded username.
            attr_reader :username

            def initialize(authorization)
              super
              @username, @password =
                Base64.decode64(auth_param).split(':', 2) \
                if auth_scheme == 'Basic' && auth_param.present?
            end

            def well_formed? # :nodoc:
              !username.nil? && !password.nil?
            end
          end
        end
      end
    end
  end
end
