# frozen_string_literal: true

module Jsapi
  module Messages # :nodoc:
    class << self
      def invalid_value(name:, value:, valid_values: [])
        case valid_values.count
        when 0
          "#{name} must not be #{value.inspect}"
        when 1
          "#{name} must be #{valid_values.first.inspect}, is #{value.inspect}"
        else
          "#{name} must be one of #{valid_values[0..-2].map(&:inspect).join(', ')} " \
          "or #{valid_values.last.inspect}, is #{value.inspect}"
        end
      end
    end
  end
end
