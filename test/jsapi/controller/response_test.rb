# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseTest < Minitest::Test
      # #initialize

      def test_initialize_raises_an_error_when_omit_is_invalid
        response_model = Meta::Response.new(type: 'boolean')

        error = assert_raises(InvalidArgumentError) do
          Response.new({}, response_model, definitions, omit: :foo)
        end
        assert_equal('omit must be one of :empty or :nil, is :foo', error.message)
      end

      # #to_json

      def test_to_json_on_boolean
        response_model = Meta::Response.new(type: 'boolean')

        response = Response.new(true, response_model, definitions)
        assert_equal('true', response.to_json)

        response = Response.new(false, response_model, definitions)
        assert_equal('false', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_integer
        response_model = Meta::Response.new(type: 'integer')

        response = Response.new(1, response_model, definitions)
        assert_equal('1', response.to_json)

        response = Response.new(1.0, response_model, definitions)
        assert_equal('1', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_integer_with_conversion
        response_model = Meta::Response.new(type: 'integer', conversion: :abs)

        response = Response.new(-1, response_model, definitions)
        assert_equal('1', response.to_json)
      end

      def test_to_json_on_number
        response_model = Meta::Response.new(type: 'number')

        response = Response.new(1.0, response_model, definitions)
        assert_equal('1.0', response.to_json)

        response = Response.new(1, response_model, definitions)
        assert_equal('1.0', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_numbers_with_conversion
        response_model = Meta::Response.new(type: 'number', conversion: :abs)

        response = Response.new(-1.0, response_model, definitions)
        assert_equal('1.0', response.to_json)
      end

      # Strings

      def test_to_json_on_string
        response_model = Meta::Response.new(type: 'string')

        response = Response.new('foo', response_model, definitions)
        assert_equal('"foo"', response.to_json)

        response = Response.new('', response_model, definitions)
        assert_equal('""', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)
      end

      def test_to_json_on_string_with_date_format
        response_model = Meta::Response.new(type: 'string', format: 'date')

        response = Response.new('2099-12-31T23:59:59+00:00', response_model, definitions)
        assert_equal('"2099-12-31"', response.to_json)
      end

      def test_to_json_on_string_with_datetime_format
        response_model = Meta::Response.new(type: 'string', format: 'date-time')

        response = Response.new('2099-12-31', response_model, definitions)
        assert_equal('"2099-12-31T00:00:00.000+00:00"', response.to_json)
      end

      def test_to_json_on_string_with_duration_format
        response_model = Meta::Response.new(type: 'string', format: 'duration')

        duration = ActiveSupport::Duration.build(86_400)
        response = Response.new(duration, response_model, definitions)
        assert_equal('"P1D"', response.to_json)
      end

      def test_to_json_on_string_with_convertion
        response_model = Meta::Response.new(type: 'string', conversion: :upcase)

        response = Response.new('Foo', response_model, definitions)
        assert_equal('"FOO"', response.to_json)
      end

      def test_to_json_on_string_with_default_value
        response_model = Meta::Response.new(type: 'string')
        definitions.add_default('string', within_responses: '')

        response = Response.new(nil, response_model, definitions)
        assert_equal('""', response.to_json)
      end

      # Arrays

      def test_to_json_on_array
        response_model = Meta::Response.new(type: 'array', items: { type: 'string' })

        response = Response.new(%w[foo bar], response_model, definitions)
        assert_equal('["foo","bar"]', response.to_json)

        response = Response.new([], response_model, definitions)
        assert_equal('[]', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)

        definitions.add_default('array', within_responses: [])
        assert_equal('[]', response.to_json)
      end

      def test_to_json_raises_an_error_on_invalid_array
        response_model = Meta::Response.new(
          type: 'array',
          items: { type: 'string', existence: true }
        )
        response = Response.new([nil], response_model, definitions)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("[0] can't be nil", error.message)
      end

      # Objects

      def test_to_json_on_object
        response_model = Meta::Response.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new({ foo: 'bar' }, response_model, definitions)
        assert_equal('{"foo":"bar"}', response.to_json)

        response = Response.new({}, response_model, definitions)
        assert_equal('{"foo":null}', response.to_json)

        response = Response.new(nil, response_model, definitions)
        assert_equal('null', response.to_json)

        definitions.add_default('object', within_responses: {})
        assert_equal('{"foo":null}', response.to_json)
      end

      def test_to_json_on_object_with_additional_properties
        response_model = Meta::Response.new(
          type: 'object',
          additional_properties: { type: 'string' }
        )
        response_model.add_property('foo', type: 'string')

        response = Response.new(
          {
            foo: 'bar',
            additional_properties: {
              foo: 'foo',
              bar: 'foo'
            }
          },
          response_model,
          definitions
        )
        assert_equal('{"foo":"bar","bar":"foo"}', response.to_json)

        response = Response.new({ foo: 'bar' }, response_model, definitions)
        assert_equal('{"foo":"bar"}', response.to_json)
      end

      def test_to_json_on_object_with_additional_properties_only
        response_model = Meta::Response.new(
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
          response_model,
          definitions
        )
        assert_equal('{"foo":"bar","bar":"foo"}', response.to_json)

        response = Response.new({}, response_model, definitions)
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

        response_model = Meta::Response.new(schema: 'base')

        response = Response.new({ foo: 'bar' }, response_model, definitions)
        assert_equal('{"type":"foo","foo":"bar"}', response.to_json)

        response = Response.new({ type: 'bar', bar: 'foo' }, response_model, definitions)
        assert_equal('{"type":"bar","bar":"foo"}', response.to_json)
      end

      def test_to_json_on_object_and_omit_nil
        response_model = Meta::Response.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_nil },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        response = Response.new({}, response_model, definitions, omit: :nil)
        assert_equal('{"foo":null}', response.to_json)

        response = Response.new({}, response_model, definitions)
        assert_equal('{"foo":null,"bar":null}', response.to_json)
      end

      def test_to_json_on_object_and_omit_empty
        response_model = Meta::Response.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_empty },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        object = { foo: '', bar: '' }

        response = Response.new(object, response_model, definitions, omit: :empty)
        assert_equal('{"foo":""}', response.to_json)

        response = Response.new(object, response_model, definitions)
        assert_equal('{"foo":"","bar":""}', response.to_json)
      end

      def test_to_json_raises_an_error_on_invalid_object
        response_model = Meta::Response.new(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: true }
          }
        )
        response = Response.new({ foo: nil }, response_model, definitions)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_nested_object
        response_model = Meta::Response.new(
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
        response = Response.new({ foo: { bar: nil } }, response_model, definitions)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo.bar can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_additional_property
        response_model = Meta::Response.new(
          type: 'object',
          additional_properties: { type: 'string', existence: true }
        )
        response = Response.new(
          { additional_properties: { foo: nil } },
          response_model,
          definitions
        )
        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_nested_additional_property
        response_model = Meta::Response.new(type: 'object')
        response_model.add_property(
          'foo',
          type: 'object',
          additional_properties: { type: 'string', existence: true }
        )
        response = Response.new(
          { foo: { additional_properties: { bar: nil } } },
          response_model,
          definitions
        )
        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("foo.bar can't be nil", error.message)
      end

      # Errors

      def test_to_json_raises_an_error_on_invalid_response
        response_model = Meta::Response.new(type: 'string', existence: true)
        response = Response.new(nil, response_model, definitions)

        error = assert_raises(RuntimeError) { response.to_json }
        assert_equal("response body can't be nil", error.message)
      end

      def test_to_json_raises_an_error_on_invalid_type
        response_model = Meta::Response.new(type: 'object')
        response = Response.new({}, response_model, definitions)

        error = Meta::Schema::Base.stub_any_instance(:type, 'foo') do
          assert_raises(RuntimeError) { response.to_json }
        end
        assert_equal('response body has an invalid type: "foo"', error.message)
      end

      # I18n

      def test_i18n
        object = Object.new
        object.define_singleton_method(:foo) { I18n.t(:hello_world) }

        response_model = Meta::Response.new(
          type: 'object',
          locale: :en,
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new(object, response_model, definitions)
        assert_equal('{"foo":"Hello world"}', response.to_json)

        response_model = Meta::Response.new(
          type: 'object',
          locale: :de,
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new(object, response_model, definitions)
        assert_equal('{"foo":"Hallo Welt"}', response.to_json)
      end

      # Inspection

      def test_inspect
        response_model = Meta::Response.new(type: 'string')
        response = Response.new('foo', response_model, definitions)
        assert_equal('#<Jsapi::Controller::Response "foo">', response.inspect)
      end

      private

      def definitions
        @definitions ||= Meta::Definitions.new
      end
    end
  end
end
