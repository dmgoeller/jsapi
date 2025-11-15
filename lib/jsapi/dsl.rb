# frozen_string_literal: true

require_relative 'dsl/error'
require_relative 'dsl/base'
require_relative 'dsl/examples'
require_relative 'dsl/schema'
require_relative 'dsl/parameter'
require_relative 'dsl/request_body'
require_relative 'dsl/response'
require_relative 'dsl/callback'
require_relative 'dsl/operation'
require_relative 'dsl/path'
require_relative 'dsl/definitions'
require_relative 'dsl/class_methods'

module Jsapi
  # The \DSL to define API components.
  module DSL
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
  end
end
