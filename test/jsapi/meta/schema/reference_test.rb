# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class ReferenceTest < Minitest::Test
        include TestHelper

        # #resolve

        def test_resolve
          definitions = Definitions.new(
            schemas: {
              'foo' => { existence: :allow_empty }
            }
          )
          assert_equal(
            definitions.find_schema('foo'),
            Reference.new(ref: 'foo').resolve(definitions)
          )
        end

        def test_resolve_on_higher_existence_level
          definitions = Definitions.new(
            schemas: {
              'foo' => { existence: :allow_empty }
            }
          )
          reference = Reference.new(ref: 'foo', existence: true)

          schema = reference.resolve(definitions)
          assert_kind_of(Delegator, schema)
          assert_equal(Existence::PRESENT, schema.existence)
        end

        def test_resolve_on_lower_existence_level
          definitions = Definitions.new(
            schemas: {
              'foo' => { existence: true }
            }
          )
          reference = Reference.new(ref: 'foo', existence: :allow_empty)

          schema = reference.resolve(definitions)
          assert_kind_of(Delegator, schema)
          assert_equal(Existence::PRESENT, schema.existence)
        end

        # JSON Schema objects

        def test_json_schema_reference_object
          assert_json_equal(
            { '$ref': '#/definitions/foo' },
            Reference.new(ref: 'foo').to_json_schema
          )
        end

        # OpenAPI objects

        def test_openapi_reference_object
          reference = Reference.new(ref: 'foo')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                { '$ref': '#/definitions/foo' }
              else
                { '$ref': '#/components/schemas/foo' }
              end,
              reference,
              version
            )
          end
        end
      end
    end
  end
end
