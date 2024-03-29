# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Parameter
      class ReferenceTest < Minitest::Test
        def test_resolve
          parameter = definitions.add_parameter('foo')
          reference = Reference.new('foo')
          assert_equal(parameter, reference.resolve(definitions))
        end

        def test_raises_error_on_invalid_reference
          assert_raises(ReferenceError) do
            Reference.new('foo').resolve(Definitions.new)
          end
        end

        # OpenAPI 2.0 tests

        def test_openapi_2_0_parameter
          definitions.add_parameter('foo', type: 'string')
          reference = Reference.new('foo')

          assert_equal(
            [
              { '$ref': '#/parameters/foo' }
            ],
            reference.to_openapi_parameters('2.0', definitions)
          )
        end

        def test_openapi_2_0_object_parameter
          parameter = definitions.add_parameter('foo', type: 'object')
          parameter.schema.add_property('bar', type: 'string')
          reference = Reference.new('foo')

          assert_equal(
            [
              {
                name: 'foo[bar]',
                in: 'query',
                type: 'string',
                allowEmptyValue: true
              }
            ],
            reference.to_openapi_parameters('2.0', definitions)
          )
        end

        # OpenAPI 3.0 tests

        def test_openapi_3_0_parameter
          definitions.add_parameter('foo', type: 'string')
          reference = Reference.new('foo')

          assert_equal(
            [
              { '$ref': '#/components/parameters/foo' }
            ],
            reference.to_openapi_parameters('3.0', definitions)
          )
        end

        def test_openapi_3_0_object_parameter
          parameter = definitions.add_parameter('foo', type: 'object')
          parameter.schema.add_property('bar', type: 'string')
          reference = Reference.new('foo')

          assert_equal(
            [
              {
                name: 'foo[bar]',
                in: 'query',
                schema: {
                  type: 'string',
                  nullable: true
                },
                allowEmptyValue: true
              }
            ],
            reference.to_openapi_parameters('3.0', definitions)
          )
        end

        private

        def definitions
          @definitions ||= Definitions.new
        end
      end
    end
  end
end
