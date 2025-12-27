# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseTest < Minitest::Test
      # #initialize

      def test_initialize_raises_an_error_when_omit_is_invalid
        content_model = content_model(type: 'boolean')

        error = assert_raises(InvalidArgumentError) do
          Response.new({}, content_model, omit: :foo)
        end
        assert_equal('omit must be one of :empty or :nil, is :foo', error.message)
      end

      # #to_json

      def test_to_json_on_boolean
        content_model = content_model(type: 'boolean')

        response = Response.new(true, content_model)
        assert_equal('true', response.to_json)

        response = Response.new(false, content_model)
        assert_equal('false', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_integer
        content_model = content_model(type: 'integer')

        response = Response.new(1, content_model)
        assert_equal('1', response.to_json)

        response = Response.new(1.0, content_model)
        assert_equal('1', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_integer_with_conversion
        content_model = content_model(type: 'integer', conversion: :abs)

        response = Response.new(-1, content_model)
        assert_equal('1', response.to_json)
      end

      def test_to_json_on_number
        content_model = content_model(type: 'number')

        response = Response.new(1.0, content_model)
        assert_equal('1.0', response.to_json)

        response = Response.new(1, content_model)
        assert_equal('1.0', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_numbers_with_conversion
        content_model = content_model(type: 'number', conversion: :abs)

        response = Response.new(-1.0, content_model)
        assert_equal('1.0', response.to_json)
      end

      # Strings

      def test_to_json_on_string
        content_model = content_model(type: 'string')

        response = Response.new('foo', content_model)
        assert_equal('"foo"', response.to_json)

        response = Response.new('', content_model)
        assert_equal('""', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_string_with_date_format
        content_model = content_model(type: 'string', format: 'date')

        response = Response.new('2099-12-31T23:59:59+00:00', content_model)
        assert_equal('"2099-12-31"', response.to_json)
      end

      def test_to_json_on_string_with_datetime_format
        content_model = content_model(type: 'string', format: 'date-time')

        response = Response.new('2099-12-31', content_model)
        assert_equal('"2099-12-31T00:00:00.000+00:00"', response.to_json)
      end

      def test_to_json_on_string_with_duration_format
        content_model = content_model(type: 'string', format: 'duration')

        duration = ActiveSupport::Duration.build(86_400)
        response = Response.new(duration, content_model)
        assert_equal('"P1D"', response.to_json)
      end

      def test_to_json_on_string_with_conversion
        content_model = content_model(type: 'string', conversion: :upcase)

        response = Response.new('Foo', content_model)
        assert_equal('"FOO"', response.to_json)
      end

      def test_to_json_on_string_with_default_value
        content_model = content_model(type: 'string')
        definitions.add_default('string', within_responses: '')

        response = Response.new(nil, content_model)
        assert_equal('""', response.to_json)
      end

      # Arrays

      def test_to_json_on_array
        content_model = content_model(type: 'array', items: { type: 'string' })

        response = Response.new(%w[foo bar], content_model)
        assert_equal('["foo","bar"]', response.to_json)

        response = Response.new([], content_model)
        assert_equal('[]', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)

        definitions.add_default('array', within_responses: [])
        assert_equal('[]', response.to_json)
      end

      def test_to_json_raises_an_error_on_invalid_array
        content_model = content_model(
          type: 'array',
          items: {
            type: 'string',
            existence: true
          }
        )
        response = Response.new([nil], content_model)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("[0] can't be nil", error.message)
      end

      # Objects

      def test_to_json_on_object
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new({ foo: 'bar' }, content_model)
        assert_equal('{"foo":"bar"}', response.to_json)

        response = Response.new({}, content_model)
        assert_equal('{"foo":null}', response.to_json)

        response = Response.new(nil, content_model)
        assert_equal('null', response.to_json)

        definitions.add_default('object', within_responses: {})
        assert_equal('{"foo":null}', response.to_json)
      end

      def test_to_json_on_object_with_additional_properties
        content_model = content_model(
          type: 'object',
          additional_properties: { type: 'string' }
        )
        content_model.add_property('foo', type: 'string')

        response = Response.new(
          {
            foo: 'bar',
            additional_properties: {
              foo: 'foo',
              bar: 'foo'
            }
          },
          content_model
        )
        assert_equal('{"foo":"bar","bar":"foo"}', response.to_json)

        response = Response.new({ foo: 'bar' }, content_model)
        assert_equal('{"foo":"bar"}', response.to_json)
      end

      def test_to_json_on_object_with_additional_properties_only
        content_model = content_model(
          type: 'object',
          additional_properties: { type: 'string' }
        )
        response = Response.new(
          {
            additional_properties: {
              foo: 'bar',
              bar: 'foo'
            }
          },
          content_model
        )
        assert_equal('{"foo":"bar","bar":"foo"}', response.to_json)

        response = Response.new({}, content_model)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_object_with_polymorphism
        definitions
          .add_schema('base', discriminator: { property_name: 'type' })
          .add_property('type', type: 'string', default: 'foo')

        definitions
          .add_schema('foo', all_of: [{ ref: 'base' }])
          .add_property('foo', type: 'string')

        definitions
          .add_schema('bar', all_of: [{ ref: 'base' }])
          .add_property('bar', type: 'string')

        content_model = content_model(schema: 'base')

        response = Response.new({ foo: 'bar' }, content_model)
        assert_equal('{"type":"foo","foo":"bar"}', response.to_json)

        response = Response.new({ type: 'bar', bar: 'foo' }, content_model)
        assert_equal('{"type":"bar","bar":"foo"}', response.to_json)
      end

      def test_to_json_on_object_and_omit_nil
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_nil },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        response = Response.new({}, content_model, omit: :nil)
        assert_equal('{"foo":null}', response.to_json)

        response = Response.new({}, content_model)
        assert_equal('{"foo":null,"bar":null}', response.to_json)
      end

      def test_to_json_on_object_and_omit_empty
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_empty },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        object = { foo: '', bar: '' }

        response = Response.new(object, content_model, omit: :empty)
        assert_equal('{"foo":""}', response.to_json)

        response = Response.new(object, content_model)
        assert_equal('{"foo":"","bar":""}', response.to_json)
      end

      def test_to_json_raises_an_error_on_invalid_object
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: true }
          }
        )
        response = Response.new({ foo: nil }, content_model)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_nested_object
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => {
              type: 'object',
              properties: {
                'bar' => { type: 'string', existence: true }
              }
            }
          }
        )
        response = Response.new({ foo: { bar: nil } }, content_model)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo.bar can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_additional_property
        content_model = content_model(
          type: 'object',
          additional_properties: { type: 'string', existence: true }
        )
        response = Response.new(
          { additional_properties: { foo: nil } },
          content_model
        )
        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_nested_additional_property
        content_model = content_model(type: 'object')
        content_model.add_property(
          'foo',
          type: 'object',
          additional_properties: { type: 'string', existence: true }
        )
        response = Response.new(
          { foo: { additional_properties: { bar: nil } } },
          content_model
        )
        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo.bar can't be nil", error.message)
      end

      # Errors

      def test_to_json_raises_an_error_on_invalid_response
        content_model = content_model(type: 'string', existence: true)
        response = Response.new(nil, content_model)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("response body can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_type
        content_model = content_model(type: 'object')
        response = Response.new({}, content_model)

        error = Meta::Schema::Base.stub_any_instance(:type, 'foo') do
          assert_raises(RuntimeError) { response.to_json }
        end
        assert_equal('response body has an invalid type: "foo"', error.message)
      end

      # #write_json_seq_to

      def test_write_json_seq_to
        content_model = content_model(type: 'string')
        response = Response.new('foo', content_model)

        assert_equal(
          "\u001E\"foo\"\n",
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )
      end

      def test_write_json_seq_to_on_array
        content_model = content_model(type: 'array', items: { type: 'string' })
        response = Response.new(%w[foo bar], content_model)

        assert_equal(
          "\u001E\"foo\"\n\u001E\"bar\"\n",
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )
      end

      # I18n

      def test_i18n
        object = Object.new
        object.define_singleton_method(:foo) { I18n.t(:hello_world) }

        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new(object, content_model, locale: :en)
        assert_equal('{"foo":"Hello world"}', response.to_json)
        assert_equal(
          "\u001E{\"foo\":\"Hello world\"}\n",
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )
        response = Response.new(object, content_model, locale: :de)
        assert_equal('{"foo":"Hallo Welt"}', response.to_json)
        assert_equal(
          "\u001E{\"foo\":\"Hallo Welt\"}\n",
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string
        )
      end

      # Inspection

      def test_inspect
        response = Response.new('foo', content_model(type: 'string'))
        assert_equal('#<Jsapi::Controller::Response "foo">', response.inspect)
      end

      private

      def content_model(**keywords)
        Meta::Content::Wrapper.new(
          Meta::Content.new(**keywords),
          definitions
        )
      end

      def definitions
        @definitions ||= Meta::Definitions.new
      end
    end
  end
end
