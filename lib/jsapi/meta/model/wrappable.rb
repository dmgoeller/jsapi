# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      # Defines a +wrap+ class method to wrap an instance of the given class.
      module Wrappable
        def self.included(base) # :nodoc:
          class << base
            define_method(:wrap) do |model, definitions|
              return if model.nil?

              wrapper_class = "#{name}::Wrapper".constantize
              return model if model.is_a?(wrapper_class)

              wrapper_class.new(model, definitions)
            end
          end
        end
      end
    end
  end
end
