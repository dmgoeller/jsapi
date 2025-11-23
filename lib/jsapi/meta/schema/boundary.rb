# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Boundary
        # Transforms +value+ to an instance of this class.
        def self.from(value)
          case value
          when Boundary
            value
          when Hash
            Boundary.new(value[:value], exclusive: value[:exclusive] == true)
          else
            Boundary.new(value)
          end
        end

        # The value of the boundary.
        attr_reader :value

        def initialize(value, exclusive: false)
          @value = value
          @exclusive = exclusive
        end

        # Returns true if the boundary is exclusive, false otherwise.
        def exclusive?
          @exclusive == true
        end

        def inspect # :nodoc:
          "#<#{self.class} value: #{value}, exclusive: #{exclusive?}>"
        end
      end
    end
  end
end
