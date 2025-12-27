# frozen_string_literal: true

module Jsapi
  module Meta
    module Parameter
      class Wrapper < Model::Wrapper
        def schema
          @schema ||= Schema.wrap(super, definitions)
        end
      end
    end
  end
end
