# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Example
      class BaseTest < Minitest::Test
        include TestHelper

        def test_external_value_and_serialized_value_are_mutually_exclusive
          error = assert_raises(RuntimeError) do
            Base.new(external_value: '/foo/bar', serialized_value: '{"foo":"bar"}')
          end
          assert_equal(
            'external value and serialized value are mutually exclusive',
            error.message
          )
        end

        # external value

        def test_external_value
          example = Base.new

          example.external_value = '/foo/bar'
          assert_equal('/foo/bar', example.external_value)
        end

        def test_external_value_can_not_be_set_when_serialized_value_is_present
          example = Base.new(serialized_value: '{"foo":"bar"}')

          error = assert_raises(RuntimeError) do
            example.external_value = '/foo/bar'
          end
          assert_equal(
            'external value and serialized value are mutually exclusive',
            error.message
          )
        end

        # serialized value

        def test_serialized_value
          example = Base.new

          example.serialized_value = '{"foo":"bar"}'
          assert_equal('{"foo":"bar"}', example.serialized_value)
        end

        def test_serialized_value_can_not_be_set_when_external_value_is_present
          example = Base.new(external_value: '/foo/bar')

          error = assert_raises(RuntimeError) do
            example.serialized_value = '{"foo":"bar"}'
          end
          assert_equal(
            'external value and serialized value are mutually exclusive',
            error.message
          )
        end

        # data value

        def test_data_value
          example = Base.new(value: 'foo')
          assert_equal('foo', example.data_value)
        end

        def test_lazily_created_data_value
          builder = Class.new do
            def foo
              'bar'
            end
          end.new

          # Argument-less proc
          example = Base.new(value: -> { 'foo' })
          assert_equal('foo', example.data_value(builder: builder))

          # Single-argument proc
          example = Base.new(value: ->(b) { b.foo })
          assert_equal('bar', example.data_value(builder: builder))
        end

        # OpenAPI objects

        def test_minimal_openapi_example_object
          example = Base.new(value: 'foo')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_2
                { value: 'foo' }
              else
                { dataValue: 'foo' }
              end,
              example,
              version
            )
          end
        end

        def test_full_openapi_example_object
          example = Base.new(
            summary: 'Foo',
            description: 'Lorem ipsum',
            value: 'foo',
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              {
                summary: 'Foo',
                description: 'Lorem ipsum',
                **if version < OpenAPI::V3_2
                    { value: 'foo' }
                  else
                    { dataValue: 'foo' }
                  end,
                'x-foo': 'bar'
              },
              example,
              version
            )
          end
        end

        def test_openapi_example_object_on_proc
          example_builder = Class.new do
            def foo
              'bar'
            end
          end.new

          example = Base.new(value: ->(builder) { builder.foo })

          each_openapi_version do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_2
                { value: 'bar' }
              else
                { dataValue: 'bar' }
              end,
              example,
              version,
              builder: example_builder
            )
          end
        end

        def test_openapi_example_object_on_external_value
          example = Base.new(external_value: '/foo/bar')

          each_openapi_version do |version|
            assert_openapi_equal(
              { externalValue: '/foo/bar' },
              example,
              version
            )
          end
        end
      end
    end
  end
end
