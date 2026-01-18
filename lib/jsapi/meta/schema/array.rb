# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Array < Base
        class Wrapper < Schema::Wrapper
          def items
            @items ||= Schema.wrap(super, definitions)
          end
        end

        ##
        # :attr: items
        # The Schema defining the kind of items.
        attribute :items, Schema, accessors: %i[reader]

        ##
        # :attr: max_items
        # The maximum length of an array.
        attribute :max_items, accessors: %i[reader]

        ##
        # :attr: min_items
        # The minimum length of an array.
        attribute :min_items, accessors: %i[reader]

        def items=(keywords = {}) # :nodoc:
          try_modify_attribute!(:items) do
            if keywords.key?(:schema)
              keywords = keywords.dup
              keywords[:ref] = keywords.delete(:schema)
            end
            @items = Schema.new(keywords)
          end
        end

        def max_items=(value) # :nodoc:
          try_modify_attribute!(:max_items) do
            add_validation('max_items', Validation::MaxItems.new(value))
            @max_items = value
          end
        end

        def min_items=(value) # :nodoc:
          try_modify_attribute!(:min_items) do
            add_validation('min_items', Validation::MinItems.new(value))
            @min_items = value
          end
        end

        def to_json_schema # :nodoc:
          super.merge(items: items&.to_json_schema || {})
        end

        def to_openapi(version, *) # :nodoc:
          super.merge(items: items&.to_openapi(version) || {})
        end
      end
    end
  end
end
