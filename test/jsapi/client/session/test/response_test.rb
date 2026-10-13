# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    module Session
      module Test
        class ResponseTest < Minitest::Test
          def test_code
            [:ok, 200, '200', nil].each do |status_code|
              assert_equal('200', Response.new(status_code).code)
            end
            [:created, 201, '201'].each do |status_code|
              assert_equal('201', Response.new(status_code).code)
            end
          end

          def test_body
            assert_nil(Response.new(nil, nil).body)
            assert_equal('', Response.new(nil, '').body)
            assert_equal('foo', Response.new(nil, 'foo').body)
          end

          def test_content_type
            ['application/json', ''].each do |content_type|
              assert_equal(
                content_type,
                Response.new(content_type: content_type).content_type
              )
            end
            assert_nil(Response.new.content_type)
          end

          def test_headers
            assert_equal(
              {
                'content-length' => '2048',
                'content-type' => 'application/json'
              },
              Response.new(
                content_length: 2048,
                content_type: 'application/json'
              ).headers
            )
          end

          def test_each_header
            each_header = Response.new(
              content_length: 2048,
              content_type: 'application/json'
            ).each_header

            assert_kind_of(Enumerator, each_header)

            assert_equal(
              [
                ['content-length', '2048'],
                ['content-type', 'application/json']
              ],
              each_header.to_a
            )
          end

          # Inspection

          def test_inspect
            assert_equal(
              '#<Jsapi::Client::Session::Test::Response code: 200, body: nil, headers: {}>',
              Response.new.inspect
            )
          end
        end
      end
    end
  end
end
