# frozen_string_literal: true

require 'test_helper'

require_relative '../../test_helper'

module Jsapi
  module Meta
    module Schema
      module Validation
        class PatternTest < Minitest::Test
          include TestHelper

          def test_raises_exception_on_invalid_pattern
            error = assert_raises(ArgumentError) { Pattern.new(nil) }
            assert_equal('invalid pattern: nil', error.message)
          end

          def test_validates_pattern
            pattern = Pattern.new(/fo/)

            errors = Jsapi::Model::Errors.new
            assert(pattern.validate('foo', errors))
            assert_predicate(errors, :empty?)

            errors = Jsapi::Model::Errors.new
            assert(!pattern.validate('bar', errors))
            assert(errors.added?(:base, 'is invalid'))
          end

          def test_to_json_schema_validation
            assert_json_equal(
              { pattern: 'foo\.bar' },
              Pattern.new(/foo\.bar/).to_json_schema_validation
            )
          end

          def test_to_openapi_validation
            assert_json_equal(
              { pattern: 'foo\.bar' },
              Pattern.new(/foo\.bar/).to_openapi_validation
            )
          end
        end
      end
    end
  end
end
