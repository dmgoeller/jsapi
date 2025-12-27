# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module RequestBody
      class BaseTest < Minitest::Test
        include TestHelper

        def test_initial_contents
          contents = Base.new(
            content_type: '*/*',
            type: 'string',
            contents: {
              'application/json' => {},
              'application/vnd.foo+json' => {}
            }
          ).contents

          assert_equal(
            expected = [
              Media::Range.new('*', '*'),
              Media::Range.new('application', 'json'),
              Media::Range.new('application', 'vnd.foo+json')
            ],
            contents.keys,
            "Expected media ranges to be #{expected.inspect}."
          )
          assert_equal(
            expected = %w[string object object],
            contents.values.map(&:type),
            "Expected schema types to be #{expected.inspect}."
          )
        end

        def test_add_content
          request_body = Base.new

          content = assert_difference('request_body.contents.count', 1) do
            request_body.add_content(type: 'object')
          end
          assert(content.equal?(request_body.content('application/json')))

          content = assert_difference('request_body.contents.count', 1) do
            request_body.add_content('*/*', type: 'string')
          end
          assert(content.equal?(request_body.content('*/*')))
        end

        def test_add_content_raises_an_error_when_attributes_are_frozen
          request_body = Base.new
          request_body.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            request_body.add_content
          end
        end

        def test_content_for
          request_body = Base.new(
            contents: {
              'application/json' => {},
              'text/*' => {}
            }
          )
          application_json, text_all = request_body.contents.values
          {
            'application/json' => application_json,
            'text/plain' => text_all,
            'foo/bar' => application_json
          }.each do |media_type, expected|
            assert(
              request_body.content_for(media_type) == expected,
              "Expected #{expected.inspect} to be most appropriate " \
              "for #{media_type.inspect}."
            )
          end
        end

        def test_freeze_attributes_adds_a_content_when_none_is_present
          request_body = Base.new
          assert_changes('request_body.contents.count', from: 0, to: 1) do
            request_body.freeze_attributes
          end
        end

        def test_freeze_attributes_adds_no_content_when_at_least_one_is_present
          request_body = Base.new(content_type: 'application/json')
          assert_no_changes('request_body.contents') do
            request_body.freeze_attributes
          end
        end

        # OpenAPI objects

        def test_minimal_openapi_parameter_object
          request_body = Base.new(type: 'string', existence: true)

          assert_json_equal(
            {
              name: 'body',
              in: 'body',
              required: true,
              type: 'string'
            },
            request_body.to_openapi_parameter
          )
        end

        def test_full_openapi_parameter_object
          request_body = Base.new(
            type: 'string',
            description: 'Foo',
            openapi_extensions: { 'foo' => 'bar' }
          )
          assert_json_equal(
            {
              name: 'body',
              in: 'body',
              description: 'Foo',
              required: false,
              type: 'string',
              'x-foo': 'bar'
            },
            request_body.to_openapi_parameter
          )
        end

        def test_minimal_openapi_request_body_object
          request_body = Base.new(type: 'string', existence: true)

          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                content: {
                  'application/json' => {
                    schema: {
                      type: 'string'
                    }
                  }
                },
                required: true
              },
              request_body,
              version
            )
          end
        end

        def test_full_openapi_request_body_object
          request_body = Base.new(
            description: 'Foo',
            contents: {
              'application/vnd.foo+json' => {
                type: 'string',
                example: 'foo'
              }
            },
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                description: 'Foo',
                content: {
                  'application/vnd.foo+json' => {
                    schema:
                      if version < OpenAPI::V3_1
                        {
                          type: 'string',
                          nullable: true
                        }
                      else
                        { type: %w[string null] }
                      end,
                    examples: {
                      'default' =>
                        if version < OpenAPI::V3_2
                          { value: 'foo' }
                        else
                          { dataValue: 'foo' }
                        end
                    }
                  }
                },
                required: false,
                'x-foo': 'bar'
              },
              request_body,
              version
            )
          end
        end

        def test_openapi_request_body_with_multiple_contents
          request_body = Base.new(
            contents: {
              'application/json' => {
                type: 'string',
                existence: true
              },
              'application/vnd.foo+json' => {
                type: 'integer',
                existence: true
              }
            }
          )
          each_openapi_version(from: OpenAPI::V3_0) do |version|
            assert_openapi_equal(
              {
                content: {
                  'application/json' => {
                    schema: {
                      type: 'string'
                    }
                  },
                  'application/vnd.foo+json' => {
                    schema: {
                      type: 'integer'
                    }
                  }
                },
                required: true
              },
              request_body,
              version,
              nil
            )
          end
        end
      end
    end
  end
end
