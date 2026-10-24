# frozen_string_literal: true

module Jsapi
  module Definition
    module RequestBody
      class Wrapper < Model::Wrapper
        def content_for(media_type)
          Content.wrap(super, api)
        end
      end
    end
  end
end
