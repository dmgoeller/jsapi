# frozen_string_literal: true

require_relative 'test/response'
require_relative 'test/spy'
require_relative 'test/class_methods'

module Jsapi
  module Client
    module Session
      module Test
        def self.included(base) # :nodoc:
          base.extend(ClassMethods)
        end
      end
    end
  end
end
