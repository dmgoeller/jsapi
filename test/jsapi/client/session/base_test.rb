# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      class BaseTest < Minitest::Test
        def test_session
          http_request = Net::HTTP::Get.new('https://foo.bar/')
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

        def test_wraps_an_error
          cause = StandardError.new

          error = assert_raises(Error) do
            Net::HTTP.stub(:start, ->(*) { raise cause }) do
              Base.new('foo.bar')
            end
          end
          assert_same(cause, error.cause)
        end

        def test_finish_wraps_an_error
          cause = StandardError.new

          http = Minitest::Mock.new
          http.expect(:finish, nil) { raise cause }

          error = assert_raises(Error) do
            Net::HTTP.stub(:start, http) do
              session = Base.new('foo.bar')
              session.finish
            end
          end
          assert_same(cause, error.cause)
        end

        def test_send_request_wraps_an_error
          cause = StandardError.new

          http = Minitest::Mock.new
          http.expect(:request, nil) { raise cause }

          error = assert_raises(Error) do
            Net::HTTP.stub(:start, http) do
              session = Base.new('foo.bar')
              session.send_request(Net::HTTP::Get.new('https://foo.bar/'))
            end
          end
          assert_same(cause, error.cause)
        end

        # Testing

        def test_spy
          Base.spy do |spy|
            session = Base.new

            [200, 500].each do |code|
              request = Net::HTTP::Get.new('https://foo.bar/')
              response_body = { status: code }.to_json

              spy.response_with(code, response_body)
              response = session.send_request(request)

              assert_same(request, spy.request)
              assert_equal(code.to_s, response.code)
              assert_same(response_body, response.body)
            end
          end
        end
      end
    end
  end
end
