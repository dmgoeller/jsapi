# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseTest < Minitest::Test
      # #initialize

      def test_initialize_raises_an_error_when_omit_is_invalid
        content_model = content_model(type: 'boolean')

        error = assert_raises(ArgumentError) do
          Response.new({}, content_model, omit: :foo)
        end
        assert_equal('omit must be one of :empty or :nil, is :foo', error.message)
      end

      # JSON serialization

      def test_serializes_boolean_response
        content_model = content_model(type: 'boolean')

        # Truthy values
        response = Response.new(true, content_model)
        assert_json_equal(true, response)
        assert_json_seq_equal(json_seq('true'), response)

        response = Response.new('', content_model)
        assert_json_equal(true, response)
        assert_json_seq_equal(json_seq('true'), response)

        # Falsely values
        response = Response.new(false, content_model)
        assert_json_equal(false, response)
        assert_json_seq_equal(json_seq('false'), response)

        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('boolean', within_responses: false)
        assert_json_equal(false, response)
        assert_json_seq_equal(json_seq('false'), response)
      end

      def test_serializes_integer_response
        content_model = content_model(type: 'integer')

        response = Response.new(1, content_model)
        assert_json_equal(1, response)
        assert_json_seq_equal(json_seq('1'), response)

        response = Response.new(1.0, content_model)
        assert_json_equal(1, response)
        assert_json_seq_equal(json_seq('1'), response)

        # nil
        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('integer', within_responses: 0)
        assert_json_equal(0, response)
        assert_json_seq_equal(json_seq('0'), response)
      end

      def test_serializes_integer_response_with_conversion
        content_model = content_model(type: 'integer', conversion: :abs)

        response = Response.new(-1, content_model)
        assert_json_equal(1, response)
        assert_json_seq_equal(json_seq('1'), response)
      end

      def test_serializes_number_response
        content_model = content_model(type: 'number')

        response = Response.new(1.0, content_model)
        assert_json_equal(1.0, response)
        assert_json_seq_equal(json_seq('1.0'), response)

        response = Response.new(1, content_model)
        assert_json_equal(1.0, response)
        assert_json_seq_equal(json_seq('1.0'), response)

        # nil
        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('number', within_responses: 0.0)
        assert_json_equal(0.0, response)
        assert_json_seq_equal(json_seq('0.0'), response)
      end

      def test_serializes_number_response_with_conversion
        content_model = content_model(type: 'number', conversion: :abs)

        response = Response.new(-1.0, content_model)
        assert_json_equal(1.0, response)
        assert_json_seq_equal(json_seq('1.0'), response)
      end

      # Strings

      def test_serializes_string_response
        content_model = content_model(type: 'string')

        response = Response.new('foo', content_model)
        assert_json_equal('foo', response)
        assert_json_seq_equal(json_seq('"foo"'), response)

        response = Response.new('', content_model)
        assert_json_equal('', response)
        assert_json_seq_equal(json_seq('""'), response)

        # nil
        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('string', within_responses: '')
        assert_json_equal('', response)
        assert_json_seq_equal(json_seq('""'), response)
      end

      def test_serializes_string_response_with_date_format
        content_model = content_model(type: 'string', format: 'date')

        response = Response.new('2099-12-31T23:59:59+00:00', content_model)
        assert_json_equal('2099-12-31', response)
        assert_json_seq_equal(json_seq('"2099-12-31"'), response)
      end

      def test_serializes_string_response_with_datetime_format
        content_model = content_model(type: 'string', format: 'date-time')

        response = Response.new('2099-12-31', content_model)
        assert_json_equal('2099-12-31T00:00:00.000+00:00', response)
        assert_json_seq_equal(json_seq('"2099-12-31T00:00:00.000+00:00"'), response)
      end

      def test_serializes_string_response_with_duration_format
        content_model = content_model(type: 'string', format: 'duration')

        duration = ActiveSupport::Duration.build(86_400)
        response = Response.new(duration, content_model)
        assert_json_equal('P1D', response)
        assert_json_seq_equal(json_seq('"P1D"'), response)
      end

      def test_serializes_string_with_conversion
        content_model = content_model(type: 'string', conversion: :upcase)

        response = Response.new('Foo', content_model)
        assert_json_equal('FOO', response)
        assert_json_seq_equal(json_seq('"FOO"'), response)
      end

      # Arrays

      def test_serializes_array_response
        content_model = content_model(type: 'array', items: { type: 'string' })

        response = Response.new(%w[foo bar], content_model)
        assert_json_equal(%w[foo bar], response)
        assert_json_seq_equal(json_seq('"foo"', '"bar"'), response)

        response = Response.new([], content_model)
        assert_json_equal([], response)
        assert_json_seq_equal('', response)

        # nil
        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('array', within_responses: [])
        assert_json_equal([], response)
        assert_json_seq_equal('', response)
      end

      def test_raises_an_error_on_invalid_array
        content_model = content_model(
          type: 'array',
          items: {
            type: 'string',
            existence: true
          }
        )
        response = Response.new([nil], content_model)

        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("[0] can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0] can't be nil", error.message)
      end

      # Objects

      def test_serializes_object_response
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        )
        response = Response.new({ foo: 'bar' }, content_model)
        assert_json_equal({ 'foo' => 'bar' }, response)
        assert_json_seq_equal(json_seq('{"foo":"bar"}'), response)

        response = Response.new({}, content_model)
        assert_json_equal({ 'foo' => nil }, response)
        assert_json_seq_equal(json_seq('{"foo":null}'), response)

        # nil
        response = Response.new(nil, content_model)
        assert_json_equal(nil, response)
        assert_json_seq_equal(json_seq('null'), response)

        definitions.add_default('object', within_responses: {})
        assert_json_equal({ 'foo' => nil }, response)
        assert_json_seq_equal(json_seq('{"foo":null}'), response)
      end

      def test_serializes_object_response_with_additional_properties
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'integer' }
          },
          additional_properties: { type: 'string' }
        )
        struct = Struct.new(:foo, :additional_properties, keyword_init: true)

        # Object
        response = Response.new(
          struct.new(foo: 1, additional_properties: { bar: 2 }),
          content_model
        )
        assert_json_equal({ 'foo' => 1, 'bar' => '2' }, response)
        assert_json_seq_equal(json_seq('{"foo":1,"bar":"2"}'), response)

        # Object without additional properties
        response = Response.new(
          struct.new(foo: 1),
          content_model
        )
        assert_json_equal({ 'foo' => 1 }, response)
        assert_json_seq_equal(json_seq('{"foo":1}'), response)

        # Hash
        response = Response.new(
          {
            foo: 1,
            bar: 2
          },
          content_model
        )
        assert_json_equal({ 'foo' => 1, 'bar' => '2' }, response)
        assert_json_seq_equal(json_seq('{"foo":1,"bar":"2"}'), response)

        # Hash with explicit additional properties
        response = Response.new(
          {
            foo: 1,
            additional_properties: {
              foo: 2, # Expected to be skipped
              bar: 3
            }
          },
          content_model
        )
        assert_json_equal({ 'foo' => 1, 'bar' => '3' }, response)
        assert_json_seq_equal(json_seq('{"foo":1,"bar":"3"}'), response)

        # Hash without additional properties
        response = Response.new({ foo: 1 }, content_model)
        assert_json_equal({ 'foo' => 1 }, response)
        assert_json_seq_equal(json_seq('{"foo":1}'), response)
      end

      def test_serializes_object_response_with_additional_properties_only
        content_model = content_model(
          type: 'object',
          additional_properties: { type: 'string' }
        )
        response = Response.new(
          {
            foo: 'bar',
            bar: 'foo'
          },
          content_model
        )
        assert_json_equal({ 'foo' => 'bar', 'bar' => 'foo' }, response)
        assert_json_seq_equal(json_seq('{"foo":"bar","bar":"foo"}'), response)

        response = Response.new({}, content_model)
        assert_equal('null', response.to_json)
        assert_json_seq_equal(json_seq('null'), response)
      end

      def test_serializes_object_response_with_polymorphism
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
        assert_json_equal({ 'type' => 'foo', 'foo' => 'bar' }, response)
        assert_json_seq_equal(json_seq('{"type":"foo","foo":"bar"}'), response)

        response = Response.new({ type: 'bar', bar: 'foo' }, content_model)
        assert_json_equal({ 'type' => 'bar', 'bar' => 'foo' }, response)
        assert_json_seq_equal(json_seq('{"type":"bar","bar":"foo"}'), response)
      end

      def test_serializes_object_response_on_omit_nil
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_nil },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        response = Response.new({}, content_model, omit: :nil)
        assert_json_equal({ 'foo' => nil }, response)
        assert_json_seq_equal(json_seq('{"foo":null}'), response)

        response = Response.new({}, content_model)
        assert_json_equal({ 'foo' => nil, 'bar' => nil }, response)
        assert_json_seq_equal(json_seq('{"foo":null,"bar":null}'), response)
      end

      def test_serializes_object_response_on_omit_empty
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: :allow_empty },
            'bar' => { type: 'string', existence: :allow_omitted }
          }
        )
        object = { foo: '', bar: '' }

        response = Response.new(object, content_model, omit: :empty)
        assert_json_equal({ 'foo' => '' }, response)
        assert_json_seq_equal(json_seq('{"foo":""}'), response)

        response = Response.new(object, content_model)
        assert_json_equal({ 'foo' => '', 'bar' => '' }, response)
        assert_json_seq_equal(json_seq('{"foo":"","bar":""}'), response)
      end

      def test_raises_an_error_on_invalid_object
        content_model = content_model(
          type: 'object',
          properties: {
            'foo' => { type: 'string', existence: true }
          }
        )
        response = Response.new({ foo: nil }, content_model)

        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("foo can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0].foo can't be nil", error.message)
      end

      def test_raises_an_error_on_invalid_nested_object
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

        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("foo.bar can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0].foo.bar can't be nil", error.message)
      end

      def test_raises_an_error_on_invalid_additional_property
        content_model = content_model(
          type: 'object',
          additional_properties: { type: 'string', existence: true }
        )
        response = Response.new(
          { additional_properties: { foo: nil } },
          content_model
        )
        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("foo can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0].foo can't be nil", error.message)
      end

      def test_raises_an_error_on_invalid_nested_additional_property
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
        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("foo.bar can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0].foo.bar can't be nil", error.message)
      end

      # Errors

      def test_raises_an_error_on_invalid_response
        content_model = content_model(type: 'string', existence: true)
        response = Response.new(nil, content_model)

        error = assert_raises(RuntimeError) { response.as_json }
        assert_equal("response body can't be nil", error.message)

        error = assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        assert_equal("[0] can't be nil", error.message)
      end

      def test_raises_an_error_on_invalid_type
        content_model = content_model(type: 'object')
        response = Response.new({}, content_model)

        error = Meta::Schema::Base.stub_any_instance(:type, 'foo') do
          assert_raises(RuntimeError) { response.as_json }
        end
        assert_equal('response body has an invalid type: "foo"', error.message)

        error = Meta::Schema::Base.stub_any_instance(:type, 'foo') do
          assert_raises(RuntimeError) { response.write_json_seq_to(StringIO.new) }
        end
        assert_equal('[0] has an invalid type: "foo"', error.message)
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
        assert_json_equal({ 'foo' => 'Hello world' }, response)
        assert_json_seq_equal(json_seq('{"foo":"Hello world"}'), response)

        response = Response.new(object, content_model, locale: :de)
        assert_json_equal({ 'foo' => 'Hallo Welt' }, response)
        assert_json_seq_equal(json_seq('{"foo":"Hallo Welt"}'), response)
      end

      # Inspection

      def test_inspect
        response = Response.new('foo', content_model(type: 'string'))
        assert_equal('#<Jsapi::Controller::Response "foo">', response.inspect)
      end

      private

      def assert_json_equal(expected, response)
        human_response = response.inspect
        assert(
          (actual = response.as_json) == expected,
          "Expected #as_json to return #{expected.inspect} " \
          "for #{human_response}, is: #{actual.inspect}"
        )
        assert(
          (actual = response.to_json) == (expected = expected.to_json),
          "Expected #to_json to return #{expected.inspect} " \
          "for #{human_response}, is: #{actual.inspect}"
        )
      end

      def assert_json_seq_equal(expected, response)
        actual =
          StringIO.new.tap do |stream|
            response.write_json_seq_to(stream)
          end.string

        assert(
          actual == expected,
          "Expected #write_json_seq_to to produce #{expected.inspect} " \
          "for #{response.inspect}, is: #{actual.inspect}"
        )
      end

      def content_model(**keywords)
        Meta::Content::Wrapper.new(
          Meta::Content.new(**keywords),
          definitions
        )
      end

      def definitions
        @definitions ||= Meta::Definitions.new
      end

      def json_seq(*objects)
        objects.map { |object| "\u001E#{object}\n" }.join
      end
    end
  end
end
