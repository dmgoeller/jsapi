# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class InfoTest < Minitest::Test
      include TestHelper

      def test_empty_openapi_info_object
        each_openapi_version do |version|
          assert_openapi_equal({}, Info.new, version)
        end
      end

      def test_full_openapi_info_object
        info = Info.new(
          title: 'Foo',
          summary: 'Summary',
          description: 'Lorem ipsum',
          terms_of_service: 'Terms of service',
          contact: {
            name: 'Bar'
          },
          license: {
            name: 'MIT'
          },
          version: 1,
          openapi_extensions: { 'foo' => 'bar' }
        )
        each_openapi_version do |version|
          assert_openapi_equal(
            if version < OpenAPI::V3_1
              {
                title: 'Foo',
                description: 'Lorem ipsum',
                termsOfService: 'Terms of service',
                contact: {
                  name: 'Bar'
                },
                license: {
                  name: 'MIT'
                },
                version: '1',
                'x-foo': 'bar'
              }
            else
              {
                title: 'Foo',
                summary: 'Summary',
                description: 'Lorem ipsum',
                termsOfService: 'Terms of service',
                contact: {
                  name: 'Bar'
                },
                license: {
                  name: 'MIT'
                },
                version: '1',
                'x-foo': 'bar'
              }
            end,
            info,
            version
          )
        end
      end
    end
  end
end
