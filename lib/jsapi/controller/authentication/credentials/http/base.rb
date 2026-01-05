# frozen_string_literal: true

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          # \Base \HTTP \Authentication credentials
          class Base
            attr_reader :auth_scheme, :auth_param

            def initialize(authorization)
              @auth_scheme, @auth_param = authorization.to_s.split(' ', 2)
            end

            # Returns true if the credentials are syntactically correct.
            def well_formed?
              auth_scheme.present? && auth_param.present?
            end
          end
        end
      end
    end
  end
end
