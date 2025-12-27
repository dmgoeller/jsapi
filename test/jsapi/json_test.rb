# frozen_string_literal: true

require 'test_helper'

require_relative 'json/test_helper'

module Jsapi
  class JSONTest < Minitest::Test
    include JSON::TestHelper

    def test_wrap_array
      json_array = JSON.wrap([], schema(type: 'array'))
      assert_kind_of(JSON::Array, json_array)
    end

    def test_wrap_boolean
      json_boolean = JSON.wrap(true, schema(type: 'boolean'))
      assert_kind_of(JSON::Boolean, json_boolean)
    end

    def test_wrap_hash
      json_object = JSON.wrap({}, schema(type: 'object'))
      assert_kind_of(JSON::Object, json_object)
    end

    def test_wrap_integer
      json_integer = JSON.wrap(0, schema(type: 'integer'))
      assert_kind_of(JSON::Integer, json_integer)
    end

    def test_wrap_nil
      json_null = JSON.wrap(nil, schema)
      assert_kind_of(JSON::Null, json_null)
    end

    def test_wrap_nil_on_default
      definitions = Meta::Definitions.new
      definitions.add_default('array', within_requests: [])

      schema = schema(definitions, type: 'array')

      json_array = JSON.wrap(nil, schema, context: :request)
      assert_kind_of(JSON::Array, json_array)
      assert_equal([], json_array.value)
    end

    def test_wrap_number
      json_number = JSON.wrap(0, schema(type: 'number'))
      assert_kind_of(JSON::Number, json_number)
    end

    def test_wrap_string
      json_string = JSON.wrap('foo', schema(type: 'string'))
      assert_kind_of(JSON::String, json_string)
    end

    def test_raises_exception_on_invalid_type
      error = Meta::Schema::Base.stub_any_instance(:type, 'foo') do
        assert_raises { JSON.wrap('foo', schema) }
      end
      assert_equal('invalid type: foo', error.message)
    end
  end
end
