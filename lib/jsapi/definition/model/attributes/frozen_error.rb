# frozen_string_literal: true

module Jsapi
  module Definition
    module Model
      module Attributes
        # Raised when trying to modify a frozen attribute.
        class FrozenError < StandardError
          def initialize(target)
            super("can't modify frozen #{target.class}")
          end
        end
      end
    end
  end
end
