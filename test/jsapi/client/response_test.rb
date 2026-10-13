# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Client
    class ResponseTest < Minitest::Test
      include TestHelper

      def test_response_with_json_body
        response_definition = response_definition(
          contents: {
            'application/json' => {
              type: 'object',
              existence: true,
              properties: {
                'id' => {
                  type: 'integer',
                  existence: true
                },
                'foo' => {
                  type: 'string',
                  existence: true
                }
              }
            }
          }
        )
        response = Response.new(
          Session::Test::Response.new(
            :ok,
            '{"id":1,"foo":"bar"}',
            content_type: 'application/json'
          ),
          response_definition
        )
        assert_kind_of(Jsapi::Model::Base, response.content)
        assert_equal(1, response.content.id)
        assert_equal('bar', response.content.foo)
      end

      def test_responses_with_plain_text_body
        response_definition = response_definition(
          contents: {
            'text/plain' => {
              type: 'string',
              existence: true
            }
          }
        )
        response = Response.new(
          Session::Test::Response.new(200, 'Lorem ipsum', content_type: 'text/plain'),
          response_definition
        )
        assert_equal('Lorem ipsum', response.content)
      end

      def test_response_with_binary_body
        response = Response.new(
          Session::Test::Response.new(
            :ok,
            binary_image_data =
              "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52" \
              "\x00\x00\x00\x01\x00\x00\x00\x01\x01\x00\x00\x00\x00\x37\x6E\xF9" \
              "\x24\x00\x00\x00\x0A\x49\x44\x41\x54\x78\x9C\x63\x60\x00\x00\x00" \
              "\x02\x00\x01\x73\x75\x01\x18\x00\x00\x00\x00\x49\x45\x4E\x44\xAE" \
              "\x42\x60\x82",
            content_type: 'image/png'
          ),
          response_definition(
            contents: {
              'image/png' => {
                type: nil
              }
            }
          )
        )
        assert_same(binary_image_data, response.content)
      end

      # Headers

      def test_headers
        headers = Response.new(
          Session::Test::Response.new(
            :ok,
            content_type: 'application/json',
            content_length: '2048',
            date: '2099-12-31'
          ),
          response_definition(
            headers: {
              'content-length' => {
                type: 'integer'
              },
              'date' => {
                type: 'string',
                format: 'date'
              }
            }
          )
        ).headers

        assert_equal(
          {
            'content-type' => 'application/json',
            'content-length' => 2048,
            'date' => Date.new(2099, 12, 31)
          },
          headers.each.to_h
        )
      end

      # Media type

      def test_media_type
        media_type = Response.new(
          Session::Test::Response.new(
            :ok,
            '{"id":1,"foo":"bar"}',
            content_type: 'application/json'
          ),
          response_definition(
            contents: {
              'application/json' => {}
            }
          )
        ).media_type

        assert_kind_of(Media::Type, media_type)
        assert_equal('application', media_type.type)
        assert_equal('json', media_type.subtype)
      end

      # Status code

      def test_status_code
        status_code = Response.new(
          Session::Test::Response.new(
            :ok,
            '{"id":1,"foo":"bar"}',
            content_type: 'application/json'
          ),
          response_definition(
            contents: {
              'application/json' => {}
            }
          )
        ).status_code

        assert_kind_of(Status::Code, status_code)
        assert_equal(200, status_code.to_i)
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::Client::Response ' \
          '#<Jsapi::Client::Session::Test::Response ' \
          'code: 200, body: nil, headers: {"content-type"=>"application/json"}>>',
          Response.new(
            Session::Test::Response.new(:ok, content_type: 'application/json'),
            response_definition(
              contents: {
                'application/json' => {}
              }
            )
          ).inspect
        )
      end
    end
  end
end
