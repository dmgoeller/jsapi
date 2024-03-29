# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class RequestBodyTest < Minitest::Test
      def test_example
        request_body = RequestBody.new(type: 'string', example: 'foo')
        assert_equal('foo', request_body.examples['default'].value)
      end

      def test_required
        request_body = RequestBody.new(type: 'string', existence: true)
        assert(request_body.required?)
      end

      def test_not_required
        request_body = RequestBody.new(type: 'string', existence: false)
        assert(!request_body.required?)
      end

      # OpenAPI tests

      def test_openapi_parameter
        request_body = RequestBody.new(type: 'string')

        assert_equal(
          {
            name: 'body',
            in: 'body',
            required: false,
            type: 'string'
          },
          request_body.to_openapi_parameter
        )
      end

      def test_openapi_request_body
        request_body = RequestBody.new(type: 'string')

        assert_equal(
          {
            content: {
              'application/json' => {
                schema: {
                  type: 'string',
                  nullable: true
                }
              }
            },
            required: false
          },
          request_body.to_openapi_request_body('3.0')
        )
      end
    end
  end
end
