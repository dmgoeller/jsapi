# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      class SingleRequestTest < Minitest::Test
        def test_single_request_session
          http_request = Net::HTTP::Get.new(URI('https://foo.bar/'))
          http_response = Test::Response.new(204)

          http = Minitest::Mock.new
          http.expect(:request, http_response, [http_request])
          http.expect(:finish, nil)

          result = Net::HTTP.stub(:start, http) do
            session = SingleRequest.new('foo.bar')
            session.send_request(http_request)
          end

          assert_same(http_response, result)
          http.verify
        end

        def test_finishes_session_on_error
          http = Minitest::Mock.new
          http.expect(:request, nil) { raise Net::ReadTimeout }
          http.expect(:finish, nil)

          assert_raises(Error) do
            Net::HTTP.stub(:start, http) do
              session = SingleRequest.new('foo.bar')
              session.send_request(Net::HTTP::Get.new(URI('https://foo.bar/')))
            end
          end

          http.verify
        end

        # Testing

        def test_spy
          response_body = '{"foo":"bar"}'

          SingleRequest.spy(:ok, response_body) do |spy|
            session = SingleRequest.new

            request = Net::HTTP::Get.new(URI('https://foo.bar/'))
            response = session.send_request(request)

            assert_same(request, spy.request)
            assert_same(response_body, response.body)
          end
        end
      end
    end
  end
end
