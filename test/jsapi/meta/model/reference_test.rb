# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Model
      class ReferenceTest < Minitest::Test
        include TestHelper

        class Dummy < Base
          attribute :foo, String
        end

        class DummyReference < Reference
          def self.name
            'Jsapi::Meta::FooBar::Reference'
          end

          attribute :foo, String
        end

        class DummyDefinitions
          def initialize(dummies:)
            @dummies = dummies
          end

          def find_foo_bar(name)
            @dummies[name]
          end
        end

        # #reference?

        def test_reference_predicate
          assert_predicate(DummyReference.new, :reference?)
        end

        # #resolve

        def test_resolve
          definitions = DummyDefinitions.new(
            dummies: {
              'base' => base = Dummy.new,
              'base_ref' => base_ref = DummyReference.new(ref: 'base')
            }
          )
          reference = DummyReference.new(ref: 'base')
          assert_equal(base, reference.resolve(definitions))

          reference = DummyReference.new(ref: 'base_ref')
          assert_equal(base_ref, reference.resolve(definitions, deep: false))

          reference = DummyReference.new(ref: 'foo')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'foo'", error.message)
        end

        # #resolve_lazily

        def test_resolve_lazily
          definitions = DummyDefinitions.new(
            dummies: {
              'base' => Dummy.new(foo: 'bar'),
              'base_ref' => DummyReference.new(ref: 'base')
            }
          )
          reference = DummyReference.new(ref: 'base')
          assert_equal('bar', reference.resolve_lazily(definitions).foo)

          reference = DummyReference.new(ref: 'base_ref')
          assert_equal('bar', reference.resolve_lazily(definitions).foo)

          reference = DummyReference.new(ref: 'base', foo: 'baz')
          assert_equal('baz', reference.resolve_lazily(definitions).foo)

          reference = DummyReference.new(ref: 'foo')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'foo'", error.message)
        end

        def test_resolve_lazily_respond_to
          definitions = DummyDefinitions.new(
            dummies: {
              'foo' => Dummy.new
            }
          )
          reference = DummyReference.new(ref: 'foo').resolve_lazily(definitions)
          assert(reference.respond_to?(:foo))
          assert_not(reference.respond_to?(:bar))
        end

        # OpenAPI reference objects

        def test_minimal_openapi_reference_object
          reference = DummyReference.new(ref: 'foo')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                { '$ref': '#/fooBars/foo' }
              else
                { '$ref': '#/components/fooBars/foo' }
              end,
              reference,
              version,
              nil
            )
          end
        end

        def test_full_openapi_reference_object
          reference = DummyReference.new(
            ref: 'foo',
            summary: 'Lorem ipsum',
            description: 'Dolor sit amet'
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                { '$ref': '#/fooBars/foo' }
              when OpenAPI::V3_0
                { '$ref': '#/components/fooBars/foo' }
              else
                {
                  '$ref': '#/components/fooBars/foo',
                  summary: 'Lorem ipsum',
                  description: 'Dolor sit amet'
                }
              end,
              reference,
              version,
              nil
            )
          end
        end
      end
    end
  end
end
