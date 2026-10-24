# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      class LoggerTest < Minitest::Test
        # Requests

        def test_logs_request
          request = Net::HTTP::Post.new(URI('https://foo.bar/api/foos'))
          request.body = '{"bar":"baz"}'

          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer))
          logger.log_request(request)

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [REQ] POST /api/foos
            OUT
            buffer.string
          )
        end

        def test_logs_request_including_body
          request = Net::HTTP::Post.new(URI('https://foo.bar/api/foos'))
          request.body = '{"bar":"baz"}'

          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer), body: true)
          logger.log_request(request)

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [REQ] POST /api/foos
              [JSAPI CLIENT] [REQ] {"bar":"baz"}
            OUT
            buffer.string
          )
        end

        def test_skips_empty_request_body
          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer), body: true)
          logger.log_request(Net::HTTP::Get.new(URI('https://foo.bar/api/foos')))

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [REQ] GET /api/foos
            OUT
            buffer.string
          )
        end

        def test_does_not_log_request_at_info_level
          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer, level: :info))
          logger.log_request(Net::HTTP::Get.new(URI('https://foo.bar/api/foos')))

          assert_empty(buffer.string)
        end

        # Responses

        def test_logs_response
          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer), body: false)
          logger.log_response(Test::Response.new(200, '{"foo":"bar"}'))

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [RES] HTTP/1.1 200
            OUT
            buffer.string
          )
        end

        def test_logs_response_including_body
          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer), body: true)
          logger.log_response(Test::Response.new(200, '{"foo":"bar"}'))

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [RES] HTTP/1.1 200
              [JSAPI CLIENT] [RES] {"foo":"bar"}
            OUT
            buffer.string
          )
        end

        def test_does_not_log_response_at_info_level
          buffer = StringIO.new
          logger = Logger.new(::Logger.new(buffer, level: :info))
          logger.log_response(Test::Response.new(200, '{"foo":"bar"}'))

          assert_empty(buffer.string)
        end
      end
    end
  end
end
