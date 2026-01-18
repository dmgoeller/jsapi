# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      # Wraps a meta model
      class Wrapper < SimpleDelegator
        attr_reader :definitions

        def initialize(model, definitions)
          super(model.resolve(definitions))
          @definitions = definitions
        end

        def ==(other) # :nodoc:
          other.is_a?(self.class) &&
            __getobj__ == other.__getobj__
        end

        def inspect # :nodoc:
          "#<#{self.class.name} #{super}>"
        end
      end
    end
  end
end
