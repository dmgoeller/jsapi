# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Client
    class ResponseHeadersTest < Minitest::Test
      include TestHelper

      def test_array_header
        headers = Response::Headers.new(
          Session::Test::Response.new(:ok, x_array: 'foo,bar'),
          response_definition(
            headers: {
              'x-array' => {
                type: 'array',
                items: {
                  type: 'string'
                }
              }
            }
          )
        )
        assert_equal(%w[foo bar], headers['x-array'])
      end

      def test_date_header
        headers = Response::Headers.new(
          Session::Test::Response.new(:ok, date: '2099-12-31'),
          response_definition(
            headers: {
              'date' => {
                type: 'string',
                format: 'date'
              }
            }
          )
        )
        assert_equal(Date.new(2099, 12, 31), headers['date'])
      end

      def test_integer_header
        headers = Response::Headers.new(
          Session::Test::Response.new(:ok, content_length: '2048'),
          response_definition(
            headers: {
              'content-length' => {
                type: 'integer'
              }
            }
          )
        )
        assert_equal(2048, headers['content-length'])
      end

      def test_bracket_operator
        headers = Response::Headers.new(
          Session::Test::Response.new(:ok, content_type: 'application/json'),
          response_definition
        )
        %w[CONTENT-TYPE Content-Type content-type].each do |name|
          assert_equal('application/json', headers[name])
        end
      end
    end
  end
end
