# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class Boolean < Base
        class Wrapper < Schema::Wrapper
          private

          def jsonify_value(value, **)
            value ? true : false
          end
        end
      end
    end
  end
end
