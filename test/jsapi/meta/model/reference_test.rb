# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Model
      class ReferenceTest < Minitest::Test
        class DummyReference < Reference
          def self.name
            'Jsapi::Meta::Model::FooBar::Reference'
          end
        end

        # #reference?

        def test_reference_predicate
          assert_predicate(DummyReference.new, :reference?)
        end

        # #resolve

        def test_resolve
          definitions = Class.new do
            def initialize(**args)
              @args = args.stringify_keys
            end

            def find_foo_bar(name)
              @args[name]
            end
          end.new(foo: model = Base.new)

          reference = DummyReference.new(ref: 'foo')
          assert_equal(model, reference.resolve(definitions))

          reference = DummyReference.new(ref: 'bar')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'bar'", error.message)
        end

        # OpenAPI reference objects

        def test_minimal_openapi_reference_object
          reference = DummyReference.new(ref: 'foo')

          # OpenAPI 2.0
          assert_equal(
            { '$ref': '#/fooBars/foo' },
            reference.to_openapi('2.0')
          )
          # OpenAPI 3.x
          %w[3.0 3.1 3.2].each do |version|
            assert_equal(
              { '$ref': '#/components/fooBars/foo' },
              reference.to_openapi(version)
            )
          end
        end

        def test_full_openapi_reference_object
          reference = DummyReference.new(
            ref: 'foo',
            summary: 'Lorem ipsum',
            description: 'Dolor sit amet'
          )
          # OpenAPI 2.0
          assert_equal(
            { '$ref': '#/fooBars/foo' },
            reference.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            { '$ref': '#/components/fooBars/foo' },
            reference.to_openapi('3.0')
          )
          # OpenAPI 3.1 and 3.2
          %w[3.1 3.2].each do |version|
            assert_equal(
              {
                '$ref': '#/components/fooBars/foo',
                summary: 'Lorem ipsum',
                description: 'Dolor sit amet'
              },
              reference.to_openapi(version)
            )
          end
        end
      end
    end
  end
end
