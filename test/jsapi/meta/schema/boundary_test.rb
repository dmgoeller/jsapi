# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Schema
      class BoundaryTest < Minitest::Test
        def test_from_boundary
          boundary = Boundary.new(1, exclusive: true)
          assert(boundary.equal?(Boundary.from(boundary)))
        end

        def test_from_integer
          boundary = Boundary.from(1)
          assert_equal(1, boundary.value)
          assert_not(boundary.exclusive?)
        end

        def test_from_hash
          boundary = Boundary.from({ value: 1, exclusive: true })
          assert_equal(1, boundary.value)
          assert(boundary.exclusive?)

          boundary = Boundary.from({ value: 2 })
          assert_equal(2, boundary.value)
          assert_not(boundary.exclusive?)
        end

        # Inspection

        def test_inspect
          assert_equal(
            '#<Jsapi::Meta::Schema::Boundary value: 1, exclusive: false>',
            Boundary.new(1).inspect
          )
        end
      end
    end
  end
end
