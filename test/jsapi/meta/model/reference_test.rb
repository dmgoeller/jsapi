# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'
require_relative 'dummy'

module Jsapi
  module Meta
    module Model
      class ReferenceTest < Minitest::Test
        include TestHelper

        def test_reference_predicate
          assert_predicate(Dummy::Reference.new, :reference?)
        end

        def test_resolve
          definitions = Dummy::Definitions.new(
            dummies: {
              'base' => base = Dummy::Base.new,
              'base_ref' => base_ref = Dummy::Reference.new(ref: 'base')
            }
          )
          reference = Dummy::Reference.new(ref: 'base')
          assert_equal(base, reference.resolve(definitions))

          reference = Dummy::Reference.new(ref: 'base_ref')
          assert_equal(base_ref, reference.resolve(definitions, deep: false))

          reference = Dummy::Reference.new(ref: 'foo')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'foo'", error.message)
        end

        def test_resolve_lazily
          definitions = Dummy::Definitions.new(
            dummies: {
              'base' => Dummy::Base.new(foo: 'bar'),
              'base_ref' => Dummy::Reference.new(ref: 'base')
            }
          )
          reference = Dummy::Reference.new(ref: 'base')
          assert_equal('bar', reference.resolve_lazily(definitions).foo)

          reference = Dummy::Reference.new(ref: 'base_ref')
          assert_equal('bar', reference.resolve_lazily(definitions).foo)

          reference = Dummy::Reference.new(ref: 'base', foo: 'baz')
          assert_equal('baz', reference.resolve_lazily(definitions).foo)

          reference = Dummy::Reference.new(ref: 'foo')
          error = assert_raises(ReferenceError) { reference.resolve(definitions) }
          assert_equal("reference can't be resolved: 'foo'", error.message)
        end

        def test_resolve_lazily_respond_to
          definitions = Dummy::Definitions.new(
            dummies: {
              'foo' => Dummy::Base.new
            }
          )
          reference = Dummy::Reference.new(ref: 'foo')
          resolved = reference.resolve_lazily(definitions)

          assert(resolved.respond_to?(:foo))
          assert_not(resolved.respond_to?(:bar))
        end

        # OpenAPI reference objects

        def test_minimal_openapi_reference_object
          reference = Dummy::Reference.new(ref: 'foo')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                { '$ref': '#/dummies/foo' }
              else
                { '$ref': '#/components/dummies/foo' }
              end,
              reference,
              version,
              nil
            )
          end
        end

        def test_full_openapi_reference_object
          reference = Dummy::Reference.new(
            ref: 'foo',
            summary: 'Lorem ipsum',
            description: 'Dolor sit amet'
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                { '$ref': '#/dummies/foo' }
              when OpenAPI::V3_0
                { '$ref': '#/components/dummies/foo' }
              else
                {
                  '$ref': '#/components/dummies/foo',
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
