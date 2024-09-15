# frozen_string_literal: true

module Jsapi
  module DSL
    module OpenAPI
      module Examples
        # Adds an example.
        #
        #   example 'foo', value: 'bar'
        #
        #   example 'foo'
        #
        # The default name is <code>'default'</code>.
        def example(name_or_value = nil, **keywords, &block)
          _define('example', name_or_value&.inspect) do
            if keywords.any? || block
              # example 'foo', value: 'bar', ...
              name = name_or_value
            else
              # example 'foo'
              name = nil
              keywords = { value: name_or_value }
            end

            example = _meta_model.add_example(name, keywords)
            Node.new(example, &block) if block
          end
        end
      end
    end
  end
end
