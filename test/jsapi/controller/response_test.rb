# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseTest < Minitest::Test
      # JSON serialization

      def test_json_response
        content_model = content_model(
          type: 'object',
          existence: true,
          properties: {
            'foo' => {
              type: 'string',
              existence: true
            }
          }
        )

        # Valid response
        response = Response.new({ foo: 'bar' }, content_model)

        assert_equal({ 'foo' => 'bar' }, response.as_json)
        assert_equal('{"foo":"bar"}', response.to_json)

        # Invalid responses
        response = Response.new(nil, content_model)
        error = assert_raises(JsonifyError) { response.as_json }
        assert_equal("response body can't be nil", error.message)

        response = Response.new({ foo: nil }, content_model)
        error = assert_raises(JsonifyError) { response.as_json }
        assert_equal("foo can't be nil", error.message)
      end

      def test_localized_json_response
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        object = Class.new do
          def foo
            I18n.t(:hello_world)
          end
        end.new

        response = Response.new(object, content_model, locale: :en)
        assert_equal({ 'foo' => 'Hello world' }, response.as_json)

        response = Response.new(object, content_model, locale: :de)
        assert_equal({ 'foo' => 'Hallo Welt' }, response.as_json)
      end

      # JSON seq

      def test_json_seq
        content_model = content_model(
          Meta::Definitions.new(
            defaults: {
              'array' => { within_responses: [] }
            }
          ),
          type: 'array',
          items: {
            type: 'object',
            existence: true,
            properties: {
              'foo' => { type: 'string' }
            }
          }
        )

        # Valid responses
        response = Response.new([{}, { foo: 'bar' }], content_model)
        assert_equal(
          <<~JSON_SEQ,
            \u001E{"foo":null}
            \u001E{"foo":"bar"}
          JSON_SEQ
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )

        response = Response.new(nil, content_model)
        assert_empty(
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )

        # Invalid response
        response = Response.new([nil], content_model)

        error = assert_raises(JsonifyError) do
          response.write_json_seq_to(StringIO.new)
        end
        assert_equal("[0] can't be nil", error.message)
      end

      def test_localized_json_seq
        content_model = content_model(
          type: 'array',
          items: {
            type: 'object',
            properties: {
              'foo' => { type: 'string' }
            }
          }
        )
        object = Class.new do
          def foo
            I18n.t(:hello_world)
          end
        end.new

        { en: 'Hello world', de: 'Hallo Welt' }.each do |locale, expected|
          response = Response.new([object], content_model, locale: locale)
          assert_equal(
            <<~JSON_SEQ,
              \u001E{"foo":"#{expected}"}
            JSON_SEQ
            StringIO.new.tap do |stream|
              response.write_json_seq_to(stream)
            end.string
          )
        end
      end

      # Inspection

      def test_inspect
        response = Response.new('foo', content_model(type: 'string'))
        assert_equal('#<Jsapi::Controller::Response "foo">', response.inspect)
      end

      private

      def content_model(definitions = nil, **keywords)
        Meta::Content::Wrapper.new(
          Meta::Content.new(**keywords),
          definitions || Meta::Definitions.new
        )
      end
    end
  end
end
