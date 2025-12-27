# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Wrapper < Model::Wrapper
        # Returns the default value within +context+.
        def default_value(context: nil)
          return default unless default.nil?

          definitions.default_value(type, context: context)
        end
      end
    end
  end
end
