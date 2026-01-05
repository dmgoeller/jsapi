# frozen_string_literal: true

require 'base64'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          # \HTTP \Bearer \Authentication credentials
          class Bearer < Base
            # The decoded token.
            attr_reader :token

            def initialize(authorization)
              super
              @token =
                Base64.decode64(auth_param) \
                if auth_scheme == 'Bearer' && auth_param.present?
            end

            def well_formed? # :nodoc:
              token.present?
            end
          end
        end
      end
    end
  end
end
