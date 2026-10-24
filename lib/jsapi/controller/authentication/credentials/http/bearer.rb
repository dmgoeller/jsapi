# frozen_string_literal: true

require 'base64'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          # Holds a token passed according to \HTTP \Bearer \Authentication.
          class Bearer < Base
            ##
            # :attr_reader: token
            # The token.

            # -
            alias token auth_param
          end
        end
      end
    end
  end
end
