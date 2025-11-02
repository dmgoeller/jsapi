# frozen_string_literal: true

require_relative 'openapi/extensions'
require_relative 'openapi/version'
require_relative 'openapi/path_item'

module Jsapi
  module Meta
    module OpenAPI
      V2_0 = Version.new(2, 0)
      V3_0 = Version.new(3, 0)
      V3_1 = Version.new(3, 1)
      V3_2 = Version.new(3, 2)
    end
  end
end
