# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module OpenAPI
      class VersionTest < Minitest::Test
        def test_from
          version = Version.from('2.0')
          assert_equal([2, 0], [version.major, version.minor])

          version = Version.from('3.0')
          assert_equal([3, 0], [version.major, version.minor])

          version = Version.from('3.1')
          assert_equal([3, 1], [version.major, version.minor])

          version = Version.from('3.2')
          assert_equal([3, 2], [version.major, version.minor])

          error = assert_raises(ArgumentError) { Version.from('1.0') }
          assert_equal('unsupported OpenAPI version: "1.0"', error.message)
        end

        def test_equality_operator
          assert_equal(Version.new(2, 0), Version.new(2, 0))
          assert(Version.new(2, 0) != Version.new(3, 0))
          assert(Version.new(3, 0) != Version.new(3, 1))
        end

        def test_comparison_operator
          assert(Version.new(2, 0) < Version.new(3, 0))
          assert(Version.new(3, 0) < Version.new(3, 1))

          assert_raises(ArgumentError) { assert_nil(Version.new(2, 0) < 3) }
        end

        def test_inspect
          assert_equal('<Jsapi::Meta::OpenAPI::Version 2.0>', Version.new(2, 0).inspect)
        end

        def test_to_s
          assert_equal('2.0', Version.new(2, 0).to_s)
        end
      end
    end
  end
end
