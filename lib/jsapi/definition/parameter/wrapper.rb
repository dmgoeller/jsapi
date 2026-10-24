# frozen_string_literal: true

module Jsapi
  module Definition
    module Parameter
      class Wrapper < Model::Wrapper
        def schema
          @schema ||= Schema.wrap(super, api)
        end
      end
    end
  end
end
