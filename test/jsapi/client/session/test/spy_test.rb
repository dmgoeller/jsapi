# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      module Test
        class SpyTest < Minitest::Test
          def test_initialize_response
            spy = Spy.new(:ok, '{"foo":"bar"}', x_foo: 'bar')
            response = spy.send_request(nil)

            assert_equal('200', response.code)
            assert_equal('{"foo":"bar"}', response.body)
            assert_equal('bar', response.headers['x-foo'])
          end

          def test_response_with
            spy = Spy.new
            spy.response_with(:ok, '{"foo":"bar"}', x_foo: 'bar')
            response = spy.send_request(nil)

            assert_equal('200', response.code)
            assert_equal('{"foo":"bar"}', response.body)
            assert_equal('bar', response.headers['x-foo'])
          end

          def test_captures_http_request
            spy = Spy.new

            http_request = Net::HTTP::Get.new('https://foo.bar/')
            spy.send_request(http_request)

            assert_same(http_request, spy.request)
          end

          def test_finish
            spy = Spy.new

            assert_changes('spy.finished?', from: false, to: true) do
              spy.finish
            end
          end
        end
      end
    end
  end
end
