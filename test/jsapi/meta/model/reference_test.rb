# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Model
      class ReferenceTest < Minitest::Test
        include TestHelper

        class DummyReference < Reference
          def self.name
            'Jsapi::Meta::Model::FooBar::Reference'
          end
        end

        class DummyDefinitions
          def initialize(**args)
            @args = args.stringify_keys
          end

          def find_foo_bar(name)
            @args[name]
          end
        end

        # #reference?

        def test_reference_predicate
          assert_predicate(DummyReference.new, :reference?)
        end

        # #resolve

        def test_resolve
          definitions = DummyDefinitions.new(
            foo: dummy = Base.new,
            foo_ref: dummy_ref = DummyReference.new(ref: 'foo')
          )
          reference = DummyReference.new(ref: 'foo')
          assert_equal(dummy, reference.resolve(definitions))

          reference = DummyReference.new(ref: 'foo_ref')
          assert_equal(dummy_ref, reference.resolve(definitions, deep: false))

          reference = DummyReference.new(ref: 'bar')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'bar'", error.message)
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
