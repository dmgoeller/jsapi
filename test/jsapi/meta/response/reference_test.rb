# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Response
      class ReferenceTest < Minitest::Test
        def test_component_type
          assert_equal('response', Reference.component_type)
        end

        def test_resolve
          definitions = Definitions.new
          response = definitions.add_response('foo')

          reference = Reference.new(ref: 'foo')
          assert_equal(response, reference.resolve(definitions))
        end

        # OpenAPI objects

        def test_openapi_reference_object
          reference = Reference.new(ref: 'foo')

          # OpenAPI 2.0
          assert_equal(
            { '$ref': '#/responses/foo' },
            reference.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            { '$ref': '#/components/responses/foo' },
            reference.to_openapi('3.0')
          )
        end
      end
    end
  end
end
