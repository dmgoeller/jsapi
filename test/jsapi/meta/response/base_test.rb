# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Response
      class BaseTest < Minitest::Test
        include TestHelper

        # Contents

        def test_initial_contents
          contents = Base.new(
            content_type: 'text/plain',
            type: 'string',
            contents: {
              'application/json' => {},
              'application/vnd.foo+json' => {}
            }
          ).contents

          assert_equal(
            expected = [
              Media::Type.new('text', 'plain'),
              Media::Type.new('application', 'json'),
              Media::Type.new('application', 'vnd.foo+json')
            ],
            contents.keys,
            "Expected media types to be #{expected.inspect}."
          )
          assert_equal(
            expected = %w[string object object],
            contents.values.map(&:type),
            "Expected schema types to be #{expected.inspect}."
          )
        end

        def test_add_content
          response = Base.new

          content = assert_difference('response.contents.count', 1) do
            response.add_content(type: 'object')
          end
          assert(content.equal?(response.content('application/json')))

          content = assert_difference('response.contents.count', 1) do
            response.add_content('text/plain', type: 'string')
          end
          assert(content.equal?(response.content('text/plain')))
        end

        def test_add_content_raises_an_error_when_attributes_are_frozen
          response = Base.new
          response.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            response.add_content
          end
        end

        def test_media_type_and_content_for
          response = Base.new(
            contents: {
              'application/json' => {},
              'text/plain' => {}
            }
          )
          application_json, text_plain = response.contents.to_a
          {
            %w[application/json text/*] => application_json,
            %w[*/* application/*] => application_json,
            %w[foo/bar] => application_json,
            %w[*/* text/*] => text_plain,
            %w[*/* text/plain] => text_plain
          }.each do |media_ranges, expected|
            assert(
              response.media_type_and_content_for(*media_ranges) == expected,
              "Expected #{expected.inspect} to be most appropriate " \
              "content for #{media_ranges.inspect}."
            )
          end
        end

        def test_media_type_and_content_for_returns_nil_if_no_content_is_present
          assert_nil(Base.new.media_type_and_content_for('*/*'))
        end

        # OpenAPI objects

        def test_minimal_openapi_response_object
          response = Base.new

          each_openapi_version do |version|
            assert_openapi_equal({}, response, version, nil)
          end
        end

        def test_full_openapi_response_object
          response = Base.new(
            summary: 'Summary of foo',
            headers: {
              'X-Foo' => { type: 'string' },
              'X-Bar' => { ref: 'X-Bar' }
            },
            contents: {
              'application/vnd.foo+json' => {
                type: 'string',
                example: 'foo'
              }
            },
            links: {
              'foo' => { operation_id: 'foo' }
            },
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                {
                  schema: {
                    type: 'string'
                  },
                  headers: {
                    'X-Foo' => {
                      type: 'string'
                    }
                  },
                  examples: {
                    'application/vnd.foo+json' => 'foo'
                  },
                  'x-foo': 'bar'
                }
              else
                {
                  **if version >= OpenAPI::V3_2
                      { summary: 'Summary of foo' }
                    else
                      {}
                    end,
                  headers: {
                    'X-Foo' => {
                      schema:
                        if version < OpenAPI::V3_1
                          {
                            type: 'string',
                            nullable: true
                          }
                        else
                          { type: %w[string null] }
                        end
                    },
                    'X-Bar' => {
                      '$ref': '#/components/headers/X-Bar'
                    }
                  },
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
                  links: {
                    'foo' => {
                      operationId: 'foo'
                    }
                  },
                  'x-foo': 'bar'
                }
              end,
              response,
              version,
              nil
            )
          end
        end

        def test_openapi_response_object_with_minimal_content
          response = Base.new(type: 'string', existence: true)

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                {
                  schema: {
                    type: 'string'
                  }
                }
              else
                {
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'string'
                      }
                    }
                  }
                }
              end,
              response,
              version,
              nil
            )
          end
        end

        def test_openapi_response_object_with_multiple_contents
          response = Base.new(
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
                }
              },
              response,
              version,
              nil
            )
          end
        end

        def test_openapi_response_object_on_json_seq
          response = Base.new(
            contents: {
              'application/json-seq' => {
                type: 'array',
                items: {
                  type: 'string',
                  existence: true
                },
                existence: true
              }
            }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                {
                  schema: {
                    type: 'array',
                    items: { type: 'string' }
                  }
                }
              when OpenAPI::V3_0, OpenAPI::V3_1
                {
                  content: {
                    'application/json-seq' => {
                      schema: {
                        type: 'array',
                        items: { type: 'string' }
                      }
                    }
                  }
                }
              else
                {
                  content: {
                    'application/json-seq' => {
                      itemSchema: {
                        type: 'string'
                      }
                    }
                  }
                }
              end,
              response,
              version,
              nil
            )
          end
        end
      end
    end
  end
end
