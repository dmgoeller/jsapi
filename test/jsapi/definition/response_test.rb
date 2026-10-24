# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class ResponseTest < Minitest::Test
      def test_new
        response = Response.new(type: 'string')
        assert_kind_of(Response::Base, response)
      end

      def test_new_reference
        response = Response.new(ref: 'foo')
        assert_kind_of(Response::Reference, response)
      end
    end
  end
end
