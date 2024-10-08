# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class NumericTest < Minitest::Test
        def test_maximum
          schema = Numeric.new(type: 'integer', maximum: 0)
          maximum = schema.validations['maximum']

          assert_predicate(maximum, :present?)
          assert_equal(0, maximum.value)
          assert(!maximum.exclusive)
        end

        def test_exclusive_maximum
          schema = Numeric.new(type: 'integer', maximum: { value: 0, exclusive: true })
          maximum = schema.validations['maximum']

          assert_predicate(maximum, :present?)
          assert_equal(0, maximum.value)
          assert(maximum.exclusive)
        end

        def test_minimum
          schema = Numeric.new(type: 'integer', minimum: 0)
          minimum = schema.validations['minimum']

          assert_predicate(minimum, :present?)
          assert_equal(0, minimum.value)
          assert(!minimum.exclusive)
        end

        def test_exclusive_minimum
          schema = Numeric.new(type: 'integer', minimum: { value: 0, exclusive: true })
          minimum = schema.validations['minimum']

          assert_predicate(minimum, :present?)
          assert_equal(0, minimum.value)
          assert(minimum.exclusive)
        end

        def test_multiple_of
          schema = Numeric.new(type: 'integer', multiple_of: 2)
          multiple_of = schema.validations['multiple_of']

          assert_predicate(multiple_of, :present?)
          assert_equal(2, multiple_of.value)
        end

        # JSON Schema objects

        def test_json_schema_object
          schema = Numeric.new(type: 'integer')
          assert_equal(
            { type: %w[integer null] },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_openapi_schema_object
          schema = Numeric.new(type: 'integer')

          # OpenAPI 2.0
          assert_equal(
            { type: 'integer' },
            schema.to_openapi('2.0')
          )
          # OpenAPI 3.0
          assert_equal(
            {
              type: 'integer',
              nullable: true
            },
            schema.to_openapi('3.0')
          )
          # OpenAPI 3.1
          assert_equal(
            { type: %w[integer null] },
            schema.to_openapi('3.1')
          )
        end
      end
    end
  end
end
