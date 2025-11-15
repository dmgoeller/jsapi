# frozen_string_literal: true

require_relative 'meta/reference_error'
require_relative 'meta/callable'
require_relative 'meta/existence'
require_relative 'meta/openapi'
require_relative 'meta/model'
require_relative 'meta/defaults'
require_relative 'meta/example'
require_relative 'meta/external_documentation'
require_relative 'meta/tag'
require_relative 'meta/server_variable'
require_relative 'meta/server'
require_relative 'meta/callback'
require_relative 'meta/contact'
require_relative 'meta/license'
require_relative 'meta/info'
require_relative 'meta/header'
require_relative 'meta/oauth_flow'
require_relative 'meta/security_scheme'
require_relative 'meta/security_requirement'
require_relative 'meta/link'
require_relative 'meta/property'
require_relative 'meta/schema'
require_relative 'meta/request_body'
require_relative 'meta/parameter'
require_relative 'meta/pathname'
require_relative 'meta/path'
require_relative 'meta/response'
require_relative 'meta/operation'
require_relative 'meta/rescue_handler'
require_relative 'meta/definitions'

module Jsapi
  # The meta model.
  module Meta end
end
