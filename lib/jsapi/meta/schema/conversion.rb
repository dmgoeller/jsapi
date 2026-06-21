# frozen_string_literal: true

require 'active_support/concern'

module Jsapi
  module Meta
    module Schema
      module Conversion
        def self.included(base) # :nodoc:
          base.attr_accessor :conversion
        end

        def convert(value)
          return value if conversion.nil?

          if conversion.respond_to?(:call)
            conversion.call(value)
          else
            value.send(conversion)
          end
        end
      end
    end
  end
end
