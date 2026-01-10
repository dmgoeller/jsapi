# frozen_string_literal: true

require_relative 'controller/operation_not_found'
require_relative 'controller/parameters_invalid'
require_relative 'controller/unauthorized'
require_relative 'controller/error'
require_relative 'controller/authentication'
require_relative 'controller/parameters'
require_relative 'controller/response'
require_relative 'controller/methods'
require_relative 'controller/actions'
require_relative 'controller/base'

module Jsapi
  # Provides classes and modules to implement API controllers.
  module Controller end
end
