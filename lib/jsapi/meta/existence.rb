# frozen_string_literal: true

module Jsapi
  module Meta
    # Combines the presence concepts of the +#present?+ method and \JSON \Schema
    # by four levels of existence.
    class Existence
      include Comparable

      # The level of existence.
      attr_reader :level

      # Creates a new instance with the specified level.
      def initialize(level)
        @level = level
      end

      # The parameter or property can be omitted, corresponds to the opposite
      # of +required+ as specified by \JSON \Schema.
      ALLOW_OMITTED = new(1)

      # The parameter or property value can be +nil+, corresponds to
      # <code>nullable: true</code> as specified by \JSON \Schema.
      ALLOW_NIL = new(2)

      # The parameter or property value must respond to +nil?+ with +false+.
      ALLOW_EMPTY = new(3)

      # The parameter or property value must respond to +present?+ with +true+
      # or must be +false+.
      PRESENT = new(4)

      # Transforms +value+ to an instance of this class.
      #
      # Raises an +ArgumentError+ if +value+ could not be transformed.
      def self.from(value)
        return value if value.is_a?(Existence)

        case value
        when :present, true
          PRESENT
        when :allow_empty
          ALLOW_EMPTY
        when :allow_nil, :allow_null
          ALLOW_NIL
        when :allow_omitted, false, nil
          ALLOW_OMITTED
        else
          raise ArgumentError, "invalid existence: #{value}"
        end
      end

      def ==(other) # :nodoc:
        other.is_a?(Existence) && level == other.level
      end

      def <=>(other) # :nodoc:
        level <=> other.level if other.is_a?(Existence)
      end

      def inspect # :nodoc:
        "#<#{self.class.name} level: #{level}>"
      end

      # Returns true if +object+ reaches the level of existence, false otherwise.
      def reach?(object)
        (object.null? ? 2 : object.empty? ? 3 : 4) >= level
      end
    end
  end
end
