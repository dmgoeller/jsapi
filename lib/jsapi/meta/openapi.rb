# frozen_string_literal: true

require_relative 'openapi/extensions'
require_relative 'openapi/version'
require_relative 'openapi/callback'
require_relative 'openapi/contact'
require_relative 'openapi/license'
require_relative 'openapi/info'
require_relative 'openapi/example'
require_relative 'openapi/external_documentation'
require_relative 'openapi/header'
require_relative 'openapi/oauth_flow'
require_relative 'openapi/security_scheme'
require_relative 'openapi/security_requirement'
require_relative 'openapi/server_variable'
require_relative 'openapi/server'
require_relative 'openapi/link'
require_relative 'openapi/tag'
require_relative 'openapi/root'

module Jsapi
  module Meta
    module OpenAPI
      class << self
        # Creates a new \OpenAPI root object.
        def new(keywords = {})
          Root.new(keywords)
        end
      end
    end
  end
end
