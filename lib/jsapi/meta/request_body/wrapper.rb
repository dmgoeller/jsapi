# frozen_string_literal: true

module Jsapi
  module Meta
    module RequestBody
      class Wrapper < Model::Wrapper
        def content_for(media_type)
          Content.wrap(super, definitions)
        end
      end
    end
  end
end
