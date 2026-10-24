# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    module Schema
      class ConversionTest < Minitest::Test
        include Conversion

        def test_skips_conversion_by_default
          foo = 'foo'
          assert_equal(foo.object_id, convert(foo).object_id)
        end

        def test_conversion_by_method_name
          self.conversion = :upcase
          assert_equal('FOO', convert('foo'))
        end

        def test_transformation_by_callable
          self.conversion = ->(s) { s.upcase }
          assert_equal('FOO', convert('foo'))
        end
      end
    end
  end
end
