# frozen_string_literal: true

module Jsapi
  module Definition
    module Model
      # Wraps a meta model
      class Wrapper < SimpleDelegator
        attr_reader :api

        def initialize(model, api)
          super(model.resolve(api))
          @api = api
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
