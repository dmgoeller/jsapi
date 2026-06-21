# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Example
      class BuilderTest < Minitest::Test
        def test_generate_json
          builder = Builder.new(
            Schema.new(
              type: :object,
              properties: {
                'foo' => { type: :string }
              }
            ),
            nil
          )
          assert_equal(
            { 'foo' => 'bar' },
            builder.generate_json({ foo: 'bar' })
          )
        end

        def test_generate_json_with_locale
          schema = Schema.new(
            type: :object,
            properties: {
              'foo' => { type: :string }
            }
          )
          object = Class.new do
            def foo
              I18n.t(:hello_world)
            end
          end.new

          assert_equal(
            { 'foo' => 'Hello world' },
            Builder.new(schema, nil, locale: :en).generate_json(object)
          )

          assert_equal(
            { 'foo' => 'Hallo Welt' },
            Builder.new(schema, nil, locale: :de).generate_json(object)
          )
        end

        def test_generate_json_raises_an_error_if_omit_is_invalid
          builder = Builder.new(Schema.new(type: 'string'), nil)

          error = assert_raises(ArgumentError) do
            builder.generate_json('foo', omit: :bar)
          end
          assert_equal('omit must be one of :empty or :nil, is :bar', error.message)
        end
      end
    end
  end
end
