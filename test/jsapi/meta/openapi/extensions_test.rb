# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module OpenAPI
      class ExtensionsTest < Minitest::Test
        include Model::Attributes
        include Extensions

        def test_with_openapi_extensions
          assert_equal({}, with_openapi_extensions)

          add_openapi_extension('foo', 'bar')
          assert_equal({ 'x-foo' => 'bar' }, with_openapi_extensions)
        end

        private

        def attribute_changed(*); end
      end
    end
  end
end
