# frozen_string_literal: true

module Jsapi
  module Media
    module TypeAndSubtype # :nodoc:
      def self.included(base)
        base.attr_reader :type, :subtype
      end

      def initialize(type, subtype)
        @type = type.downcase
        @subtype = subtype.downcase
      end

      def ==(other)
        other.is_a?(self.class) &&
          type == other.type &&
          subtype == other.subtype
      end

      alias eql? ==

      def hash
        @hash ||= [type, subtype].hash
      end

      def inspect
        "#<#{self.class} #{to_s.inspect}>"
      end

      def to_s
        @to_s ||= "#{type}/#{subtype}"
      end

      alias as_json to_s
    end
  end
end
