# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Status
    class BaseTest < Minitest::Test
      def test_equality_operator
        code = Code.from(200)

        assert(code == Code.from(200))
        assert(code != Code.from(400))
        assert(code != Range::SUCCESS)
        assert(code != DEFAULT)
      end

      def test_comparison_operator
        assert(Code.from(400) < Code.from(500))
        assert(Code.from(400) < Range::CLIENT_ERROR)
        assert(Range::CLIENT_ERROR < Range::SERVER_ERROR)
        assert(Range::SERVER_ERROR < DEFAULT)
      end

      def test_inspect
        assert_equal('#<Jsapi::Status::Code 200>', Code.from(200).inspect)
        assert_equal('#<Jsapi::Status::Range "2XX">', Range::SUCCESS.inspect)
      end
    end
  end
end
