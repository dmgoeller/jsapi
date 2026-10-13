# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Client
    class ResponseBodyTest < Minitest::Test
      include TestHelper

      def test_json_object_body
        schema = schema(
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
        )
        # Valid body
        body = Response::Body.new(
          '{"id":1,"foo":"bar"}',
          Media::Type::APPLICATION_JSON,
          schema
        )
        assert_predicate(body, :valid?)
        assert_kind_of(Jsapi::Model::Base, body.content)
        assert_equal(1, body.content.id)
        assert_equal('bar', body.content.foo)

        # Invalid bodies
        {
          '' => 'is invalid',
          '{}' => "can't be blank",
          '{"id":1}' => "'foo' can't be blank"
        }.each do |http_response_body, error_message|
          body = Response::Body.new(
            http_response_body,
            Media::Type::APPLICATION_JSON,
            schema
          )
          assert_predicate(body, :invalid?)
          assert_equal([error_message], body.errors.full_messages)
        end
      end

      def test_json_array_body
        schema = schema(
          type: 'array',
          existence: :allow_empty,
          items: {
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
        )
        # Valid body
        body = Response::Body.new(
          '[{"id":1,"foo":"bar"}]',
          Media::Type::APPLICATION_JSON,
          schema
        )
        assert_predicate(body, :valid?)
        assert_kind_of(Array, body.content)
        assert_equal(1, body.content.first.id)
        assert_equal('bar', body.content.first.foo)

        # Invalid bodies
        {
          '' => 'is invalid',
          '[{}]' => "can't be blank",
          '[{"id":1}]' => "'foo' can't be blank"
        }.each do |http_response_body, error_message|
          body = Response::Body.new(
            http_response_body,
            Media::Type::APPLICATION_JSON,
            schema
          )
          assert_predicate(body, :invalid?)
          assert_equal([error_message], body.errors.full_messages)
        end
      end

      def test_plain_text_body
        schema = schema(type: 'string', existence: true)

        # Valid body
        body = Response::Body.new(
          'Lorem ipsum',
          Media::Type::TEXT_PLAIN,
          schema
        )
        assert_predicate(body, :valid?)
        assert_kind_of(String, body.content)
        assert_equal('Lorem ipsum', body.content)

        # Invalid body
        body = Response::Body.new(
          '',
          Media::Type::TEXT_PLAIN,
          schema
        )
        assert_predicate(body, :invalid?)
        assert_equal(["can't be blank"], body.errors.full_messages)
      end

      def test_binary_body
        body = Response::Body.new(
          binary_image_data =
            "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52" \
            "\x00\x00\x00\x01\x00\x00\x00\x01\x01\x00\x00\x00\x00\x37\x6E\xF9" \
            "\x24\x00\x00\x00\x0A\x49\x44\x41\x54\x78\x9C\x63\x60\x00\x00\x00" \
            "\x02\x00\x01\x73\x75\x01\x18\x00\x00\x00\x00\x49\x45\x4E\x44\xAE" \
            "\x42\x60\x82",
          Media::Type.from('image/png'),
          nil
        )
        assert_predicate(body, :valid?)
        assert_same(binary_image_data, body.content)
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::Client::Response::Body "Lorem ipsum">',
          Response::Body.new(
            'Lorem ipsum',
            Media::Type::TEXT_PLAIN,
            schema(type: 'string')
          ).inspect
        )
      end
    end
  end
end
