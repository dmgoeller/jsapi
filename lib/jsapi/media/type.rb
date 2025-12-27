# frozen_string_literal: true

require_relative 'type_and_subtype'

module Jsapi
  module Media
    # Represents a media type.
    class Type
      include Comparable
      include TypeAndSubtype

      # Media::Type for <code>"application/json"</code>.
      APPLICATION_JSON = Type.new('application', 'json')

      # Media::Type for <code>"application/json-seq"</code>.
      APPLICATION_JSON_SEQ = Type.new('application', 'json-seq')

      # Media::Type for <code>"text/plain"</code>.
      TEXT_PLAIN = Type.new('text', 'plain')

      class << self
        # Transforms +value+ to an instance of this class.
        #
        # Raises an ArgumentError when +value+ could not be transformed.
        def from(value)
          media_type = try_from(value)
          return media_type unless media_type.nil?

          raise ArgumentError, "invalid media type: #{value.inspect}"
        end

        # Tries to transform +value+ to an instance of this class.
        #
        # Returns nil if +value+ could not be transformed.
        def try_from(value)
          return value if value.is_a?(Type)

          type_and_subtype = pattern.match(value.to_s)&.captures
          new(*type_and_subtype) if type_and_subtype&.count == 2
        end

        private

        def pattern
          @pattern ||= begin
            name = '[0-9a-zA-Z-]+'
            %r{(#{name})/(#{name}(?:\.#{name})?(?:\+#{name})?)}.freeze
          end
        end
      end

      # Compares it with +other+ by +type+ and +subtype+.
      def <=>(other)
        return unless other.is_a?(self.class)

        result = type <=> other.type
        return result unless result.zero?

        subtype <=> other.subtype
      end

      # Returns true if it represents a JSON media type as specified by
      # https://mimesniff.spec.whatwg.org/#json-mime-type.
      def json?
        (type.in?(%w[application text]) && subtype == 'json') ||
          subtype.end_with?('+json')
      end
    end
  end
end
