# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class ReferenceTest < Minitest::Test
        include TestHelper

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
