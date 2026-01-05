# frozen_string_literal: true

require_relative 'credentials/api_key'
require_relative 'credentials/http'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        class << self
          # Creates credentials from +request+ according to +security_scheme+.
          def create(request, security_scheme)
            case security_scheme
            when Meta::SecurityScheme::APIKey
              name = security_scheme.name
              APIKey.new(
                case security_scheme.in
                when 'header'
                  request.headers[name]
                when 'query'
                  request.query_parameters[name]
                end
              )
            when Meta::SecurityScheme::HTTP::Basic
              HTTP::Basic.new(request.authorization)
            when Meta::SecurityScheme::HTTP::Bearer
              HTTP::Bearer.new(request.authorization)
            when Meta::SecurityScheme::HTTP::Other
              HTTP::Base.new(request.authorization)
            end
          end
        end
      end
    end
  end
end
