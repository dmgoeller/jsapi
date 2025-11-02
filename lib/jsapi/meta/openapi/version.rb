# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      class Version
        include Comparable

        # Creates an \OpenAPI version from +version+.
        #
        # Raises an +ArgumentError+ if +version+ isn`t supported.
        def self.from(version)
          return version if version.is_a?(Version)

          case version
          when '2.0', 2, nil
            new(2, 0)
          when '3.0', 3
            new(3, 0)
          when '3.1'
            new(3, 1)
          when '3.2'
            new(3, 2)
          else
            raise ArgumentError, "unsupported OpenAPI version: #{version.inspect}"
          end
        end

        attr_reader :major, :minor

        def initialize(major, minor)
          @major = major
          @minor = minor
        end

        def ==(other) # :nodoc:
          other.is_a?(self.class) &&
            @major == other.major &&
            @minor == other.minor
        end

        def <=>(other)
          return unless other.is_a?(Version)

          result = major <=> other.major
          return result unless result.zero?

          minor <=> other.minor
        end

        def inspect
          "<#{self.class.name} #{self}>"
        end

        def to_s # :nodoc:
          "#{major}.#{minor}"
        end
      end
    end
  end
end
