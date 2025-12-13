# frozen_string_literal: true

require_relative 'actions/class_methods'

module Jsapi
  module Controller
    module Actions
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end
    end
  end
end
