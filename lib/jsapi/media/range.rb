# frozen_string_literal: true

require_relative 'type_and_subtype'

module Jsapi
  module Media
    # Represents a media range.
    class Range
      include Comparable
      include TypeAndSubtype

      # Range for all types (<code>"\*/\*"</code>).
      ALL = Range.new('*', '*')

      # Range for \JSON type (<code>"application/json"</code>).
      APPLICATION_JSON = Range.new('application', 'json')

      class << self
        # Transforms +value+ to an instance of this class.
        #
        # Raises an +ArgumentError+ when +value+ could not be transformed.
        def from(value)
          media_range = try_from(value)
          return media_range unless media_range.nil?

          raise ArgumentError, "invalid media range: #{value.inspect}"
        end

        # Reduces the given collection of media ranges by removing media ranges
        # that are already covered by another media range.
        def reduce(media_ranges)
          media_ranges.each_with_object([]) do |media_range, memo|
            media_range = from(media_range)
            if memo.none? { |other| other.cover?(media_range) }
              memo.delete_if { |other| media_range.cover?(other) }
              memo << media_range
            end
          end.sort
        end

        # Tries to transform +value+ to an instance of this class.
        #
        # Returns nil if +value+ could not be transformed.
        def try_from(value)
          return value if value.is_a?(Range)

          type_and_subtype = pattern.match(value.to_s)&.captures
          new(*type_and_subtype) if type_and_subtype&.count == 2
        end

        private

        def pattern
          @pattern ||= begin
            name = '[0-9a-zA-Z-]+'
            %r{(\*|#{name})/(\*|(?:#{name}(?:\.#{name})?(?:\+#{name})?))}.freeze
          end
        end
      end

      # Compares it with +other+ by +priority+.
      def <=>(other)
        return unless other.is_a?(self.class)

        result = priority <=> other.priority
        return result unless result.zero?

        result = type <=> other.type
        return result unless result.zero?

        subtype <=> other.subtype
      end

      # Returns true if it covers +other+.
      def cover?(other)
        return if other.nil?

        other = Range.from(other)

        (type == '*' || type == other.type) &&
          (subtype == '*' || subtype == other.subtype)
      end

      # Returns true if the given media type matches the media range.
      def match?(media_type)
        return if media_type.nil?

        media_type = Type.from(media_type)

        (type == '*' || type == media_type.type) &&
          (subtype == '*' || subtype == media_type.subtype)
      end

      alias =~ match?

      # Returns the level of priority of the media range.
      def priority
        @priority ||= (type == '*' ? 2 : 0) + (subtype == '*' ? 1 : 0) + 1
      end
    end
  end
end
