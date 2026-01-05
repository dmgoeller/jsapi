# frozen_string_literal: true

module Jsapi
  module Status
    class Base
      include Comparable

      attr_reader :priority, :value

      delegate :hash, :to_s, to: :value

      def initialize(value, priority:)
        @priority = priority
        @value = value
      end

      def ==(other) # :nodoc:
        other.is_a?(self.class) && other.value == value
      end

      alias eql? ==

      def <=>(other) # :nodoc:
        result = priority <=> other.priority
        return result unless result.zero?

        value <=> other.value
      end

      def inspect # :nodoc:
        "#<#{self.class} #{value.inspect}>"
      end
    end
  end
end
