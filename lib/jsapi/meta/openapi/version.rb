# frozen_string_literal: true

module Jsapi
  module Meta
    module OpenAPI
      class Version
        include Comparable

        # Transforms +version+ to an instance of this class.
        #
        # Raises an +ArgumentError+ if +version+ could not be transformed.
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

        def inspect # :nodoc:
          "<#{self.class.name} #{self}>"
        end

        def to_s # :nodoc:
          @to_s ||=
            case [major, minor]
            when [3, 0]
              '3.0.3'
            when [3, 1]
              '3.1.1'
            when [3, 2]
              '3.2.0'
            else
              "#{major}.#{minor}"
            end
        end

        alias as_json to_s
      end
    end
  end
end
