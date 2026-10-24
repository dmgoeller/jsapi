# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      class BaseTest < Minitest::Test
        def test_session
          http_request = Net::HTTP::Get.new(URI('https://foo.bar/'))
          http_response = Test::Response.new(200, '')

          http = Minitest::Mock.new
          http.expect(:request, http_response, [http_request])
          http.expect(:finish, nil)

          Net::HTTP.stub(:start, http) do
            session = Base.new('foo.bar')

            result = session.send_request(http_request)
            assert_same(http_response, result)

            session.finish
          end

          http.verify
        end

        def test_wraps_errors
          {
            StandardError.new => Error,
            Timeout::Error.new => TimeoutError
          }.each do |cause, wrapper_class|
            # ::new
            Net::HTTP.stub(:start, ->(*) { raise cause }) do
              assert_wraps(cause, wrapper_class, '::new') do
                Base.new('foo.bar')
              end
            end

            # #send_request and #finish
            http = Minitest::Mock.new
            http.expect(:request, nil) { raise cause }
            http.expect(:finish, nil) { raise cause }

            session = Net::HTTP.stub(:start, http) { Base.new('foo.bar') }

            assert_wraps(cause, wrapper_class, '#send_request') do
              session.send_request(Net::HTTP::Get.new(URI('https://foo.bar/')))
            end
            assert_wraps(cause, wrapper_class, '#finish') do
              session.finish
            end
          end
        end

        # Logging

        def test_logs_requests_and_responses
          http_request = Net::HTTP::Post.new(URI('https://foo.bar/api/foos'))
          http_request.body = '{"bar":"baz"}'

          http = Minitest::Mock.new
          http.expect(
            :request,
            Test::Response.new(200, '{"id":1,"bar":"baz"}'),
            [http_request]
          )
          http.expect(:finish, nil)

          buffer = StringIO.new

          session = Net::HTTP.stub(:start, http) do
            Base.new('foo.bar', 443, Logger.new(::Logger.new(buffer)))
          end
          session.send_request(http_request)
          session.finish

          assert_equal(
            <<~OUT,
              [JSAPI CLIENT] [REQ] POST /api/foos
              [JSAPI CLIENT] [RES] HTTP/1.1 200
            OUT
            buffer.string
          )
        end

        def test_wraps_logger
          session = Net::HTTP.stub(:start, Minitest::Mock.new) do
            Class.new(Base) do
              attr_reader :logger
            end.new('foo.bar', 443, ::Logger.new($stdout), body: true)
          end
          assert_kind_of(Logger, session.logger)
        end

        # Testing

        def test_spy
          Base.spy do |spy|
            session = Base.new

            [200, 500].each do |code|
              request = Net::HTTP::Get.new(URI('https://foo.bar/'))
              response_body = { status: code }.to_json

              spy.response_with(code, response_body)
              response = session.send_request(request)

              assert_same(request, spy.request)
              assert_equal(code.to_s, response.code)
              assert_same(response_body, response.body)
            end
          end
        end

        private

        def assert_wraps(cause, wrapper_class, name, &block)
          error = assert_raises(
            wrapper_class,
            "Expected #{name} to wrap #{cause} with #{wrapper_class}",
            &block
          )
          assert_same(cause, error.cause)
        end
      end
    end
  end
end
