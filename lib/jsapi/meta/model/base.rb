# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      # The base meta model class.
      class Base
        include Attributes

        # Creates a new meta model.
        #
        # Raises an +ArgumentError+ if at least one keyword is not supported.
        def initialize(keywords = {})
          merge!(keywords)
        end

        def inspect(*attributes) # :nodoc:
          klass = self.class
          attribute_names = klass.attribute_names
          attribute_names = attributes & attribute_names if attributes.any?

          "#<#{klass.name} #{
            attribute_names.map { |name| "#{name}: #{send(name).inspect}" }.join(', ')
          }>"
        end

        # Merges +keywords+ into the model.
        #
        # Raises an +ArgumentError+ if at least one keyword is not supported.
        def merge!(keywords = {})
          keywords.each do |key, value|
            if respond_to?(method = "#{key}=")
              public_send(method, value)
            else
              raise ArgumentError, "unsupported keyword: #{key}"
            end
          end
          self
        end

        # Returns false.
        def reference?
          false
        end

        # Returns itself.
        def resolve(*)
          self
        end
      end
    end
  end
end
