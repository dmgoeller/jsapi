# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class LicenseTest < Minitest::Test
      include OpenAPITestHelper

      # Identifier and URL

      def test_initialize_raises_an_error_when_identifier_and_url_are_specified_together
        error = assert_raises(RuntimeError) do
          License.new(identifier: 'MIT', url: 'https://spdx.org/licenses/MIT.html')
        end
        assert_equal('identifier and url are mutually exclusive', error.message)
      end

      def test_identifier_cannot_be_set_when_url_is_present
        license = License.new(url: 'https://spdx.org/licenses/MIT.html')

        error = assert_raises(RuntimeError) do
          license.identifier = 'MIT'
        end
        assert_equal('identifier and url are mutually exclusive', error.message)
      end

      def test_url_cannot_be_set_when_identifier_is_present
        license = License.new(identifier: 'MIT')

        error = assert_raises(RuntimeError) do
          license.url = 'https://spdx.org/licenses/MIT.html'
        end
        assert_equal('identifier and url are mutually exclusive', error.message)
      end

      # OpenAPI objects

      def test_empty_openapi_license_object
        each_openapi_version do |version|
          assert_openapi_equal({}, License.new, version)
        end
      end

      def test_openapi_license_object_with_url
        license = License.new(
          name: 'MIT License',
          url: 'https://spdx.org/licenses/MIT.html',
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            {
              name: 'MIT License',
              url: 'https://spdx.org/licenses/MIT.html',
              'x-foo': 'bar'
            },
            license,
            version
          )
        end
      end

      def test_openapi_license_object_with_identifier
        license = License.new(
          name: 'MIT License',
          identifier: 'MIT'
        )
        each_openapi_version(from: OpenAPI::V3_1) do |version|
          assert_openapi_equal(
            {
              name: 'MIT License',
              identifier: 'MIT'
            },
            license,
            version
          )
        end
      end
    end
  end
end
