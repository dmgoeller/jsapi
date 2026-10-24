# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class RequestBodyTest < Minitest::Test
      def test_new
        request_body = RequestBody.new(type: 'string')
        assert_kind_of(RequestBody::Base, request_body)
      end

      def test_new_reference
        request_body = RequestBody.new(ref: 'foo')
        assert_kind_of(RequestBody::Reference, request_body)
      end
    end
  end
end
