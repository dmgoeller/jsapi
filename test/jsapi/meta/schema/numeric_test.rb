# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class NumericTest < Minitest::Test
        include TestHelper

        def test_maximum
          schema = Numeric.new(type: 'integer', maximum: 0)
          maximum = schema.validations['maximum']

          assert_predicate(maximum, :present?)
          assert_equal(0, maximum.value)
          assert_not(maximum.exclusive)
        end

        def test_exclusive_maximum
          schema = Numeric.new(type: 'integer', maximum: { value: 0, exclusive: true })
          maximum = schema.validations['maximum']

          assert_predicate(maximum, :present?)
          assert_equal(0, maximum.value)
          assert(maximum.exclusive)
        end

        def test_maximum_raises_an_error_when_attributes_are_frozen
          schema = Numeric.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.maximum = 0
          end
        end

        def test_minimum
          schema = Numeric.new(type: 'integer', minimum: 0)
          minimum = schema.validations['minimum']

          assert_predicate(minimum, :present?)
          assert_equal(0, minimum.value)
          assert_not(minimum.exclusive)
        end

        def test_exclusive_minimum
          schema = Numeric.new(type: 'integer', minimum: { value: 0, exclusive: true })
          minimum = schema.validations['minimum']

          assert_predicate(minimum, :present?)
          assert_equal(0, minimum.value)
          assert(minimum.exclusive)
        end

        def test_minimum_raises_an_error_when_attributes_are_frozen
          schema = Numeric.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.minimum = 0
          end
        end

        def test_multiple_of
          schema = Numeric.new(type: 'integer', multiple_of: 2)
          multiple_of = schema.validations['multiple_of']

          assert_predicate(multiple_of, :present?)
          assert_equal(2, multiple_of.value)
        end

        def test_multiple_of_raises_an_error_when_attributes_are_frozen
          schema = Numeric.new
          schema.freeze_attributes

          assert_raises(Model::Attributes::FrozenError) do
            schema.multiple_of = 2
          end
        end

        # JSON Schema objects

        def test_json_schema_object
          schema = Numeric.new(type: 'integer')
          assert_json_equal(
            { type: %w[integer null] },
            schema.to_json_schema
          )
        end

        # OpenAPI objects

        def test_openapi_schema_object
          schema = Numeric.new(type: 'integer')

          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                { type: 'integer' }
              when OpenAPI::V3_0
                {
                  type: 'integer',
                  nullable: true
                }
              else
                { type: %w[integer null] }
              end,
              schema,
              version
            )
          end
        end
      end
    end
  end
end
