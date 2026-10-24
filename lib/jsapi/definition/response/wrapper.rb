# frozen_string_literal: true

module Jsapi
  module Definition
    module Response
      class Wrapper < Model::Wrapper
        # The locale of the wrapped response or reference.
        attr_reader :locale

        def initialize(response, api)
          @locale = response.resolve_lazily(api).locale
          super
        end

        def content?
          contents.lazy.any?
        end

        def contents
          super.transform_values { |content| Content.wrap(content, api) }
        end

        def content_for(*media_ranges)
          media_type_and_content_for(*media_ranges)&.second
        end

        def header_for(name)
          (@downcased_headers ||= headers.transform_keys(&:downcase))[name.to_s.downcase]
        end

        def media_type_and_content_for(*media_ranges)
          super&.then do |media_type_and_content|
            [
              media_type_and_content.first,
              Content.wrap(media_type_and_content.second, api)
            ]
          end
        end
      end
    end
  end
end
