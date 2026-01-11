# frozen_string_literal: true

module Jsapi
  module Meta
    # Represents a relative path name.
    class Pathname
      class << self
        # Transforms +name+ to an instance of this class.
        def from(name)
          return name if name.is_a?(Pathname)

          name = name[1..].presence if name&.match?(%r{\A/+\z})
          name.nil? ? new : new(name)
        end
      end

      attr_reader :segments

      delegate :hash, to: :segments

      def initialize(*segments) # :nodoc:
        @segments = segments.flat_map do |segment|
          segment = segment.to_s.delete_prefix('/')
          segment.present? ? segment.split('/', -1) : ''
        end
      end

      def ==(other) # :nodoc:
        other.is_a?(Pathname) && segments == other.segments
      end

      alias eql? ==

      # Creates a new Pathname by appending +other+ to itself.
      # Returns itself if +other+ is nil.
      def +(other)
        return self if other.nil?

        Pathname.new(*@segments, *Pathname.from(other).segments)
      end

      # Returns an array containing itself and all parent pathnames.
      def ancestors
        @ancestors ||= @segments.count.downto(0).map do |i|
          Pathname.new(*@segments[0, i])
        end
      end

      def inspect # :nodoc:
        "#<#{self.class} #{to_s.inspect}>"
      end

      # Returns the relative path name as a string.
      def to_s
        @to_s ||= @segments.presence&.each_with_index&.map do |segment, index|
          index.zero? && segment.blank? ? '//' : "/#{segment}"
        end&.join || '/'
      end

      alias as_json to_s
    end
  end
end
