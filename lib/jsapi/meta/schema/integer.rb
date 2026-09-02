# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Integer < Numeric
        class Wrapper < Schema::Wrapper
          private

          def jsonify_value(value, **)
            convert(value.to_i)
          end
        end
      end
    end
  end
end
