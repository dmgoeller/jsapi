# frozen_string_literal: true

module Jsapi
  module Meta
    module Response
      class Wrapper < Model::Wrapper
        # The locale of the wrapped response or reference.
        attr_reader :locale

        def initialize(response, definitions)
          @locale = response.resolve_lazily(definitions).locale
          super
        end

        def media_type_and_content_for(*media_ranges)
          super&.then do |media_type_and_content|
            [
              media_type_and_content.first,
              Content.wrap(media_type_and_content.second, definitions)
            ]
          end
        end
      end
    end
  end
end
