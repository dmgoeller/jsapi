# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    class ParametersTest < Minitest::Test
      # Initialization

      def test_initialize_on_header_parameter
        operation.add_parameter('x-foo', type: 'string', in: 'header')

        params = parameters(headers: { 'x-foo' => 'Value of x-foo header' })
        assert_equal('Value of x-foo header', params['x-foo'])
      end

      def test_initialize_on_query_parameter
        operation.add_parameter('foo', type: 'string')

        params = parameters(foo: 'Value of foo')
        assert_equal('Value of foo', params['foo'])
      end

      def test_initialize_on_query_parameter_as_object
        operation.add_parameter(
          'foo',
          properties: {
            'bar' => { type: 'string' }
          }
        )
        params = parameters(foo: { 'bar' => 'Value of foo.bar' })
        assert_equal('Value of foo.bar', params['foo'].bar)
      end

      def test_initialize_on_querystring_parameter
        operation.add_parameter('query', in: 'querystring', type: 'string')

        params = parameters(query_parameters: { foo: 'Value of foo' })
        assert_equal('foo=Value+of+foo', params['query'])
      end

      def test_initialize_on_querystring_parameter_as_object
        operation.add_parameter(
          'query',
          in: 'querystring',
          properties: {
            'foo' => {
              properties: {
                'bar' => { type: 'string' }
              }
            }
          }
        )
        params = parameters(query_parameters: { foo: { bar: 'Value of foo.bar' } })
        assert_equal('Value of foo.bar', params['query'].foo.bar)
      end

      def test_initialize_on_request_body
        operation.request_body = {
          type: 'object',
          properties: {
            'foo' => { type: 'string' }
          }
        }
        params = parameters(foo: 'bar')
        assert_equal('bar', params['foo'])
      end

      def test_initialize_on_query_parameter_and_request_body
        operation.add_parameter('foo', type: 'string')
        operation.request_body = {
          additional_properties: { type: 'string' }
        }
        params = parameters(foo: 'Value of foo', bar: 'Value of bar')
        assert_equal('Value of foo', params['foo'])
        assert_equal({ 'bar' => 'Value of bar' }, params.additional_attributes)
      end

      def test_initialize_on_querystring_parameter_and_request_body
        operation.add_parameter(
          'query',
          in: 'querystring',
          additional_properties: { type: 'string' }
        )
        operation.request_body = {
          additional_properties: { type: 'string' }
        }
        params = parameters(query_parameters: { foo: 'Value of foo' }, bar: 'Value of bar')
        assert_equal({ 'foo' => 'Value of foo' }, params['query'].additional_attributes)
        assert_equal({ 'bar' => 'Value of bar' }, params.additional_attributes)
      end

      # Attributes

      def test_bracket_operator
        operation.add_parameter('foo', type: 'string')
        assert_equal('Value of foo', parameters(foo: 'Value of foo')['foo'])
        assert_nil(parameters[nil])
      end

      def test_attribute_predicate
        operation.add_parameter('foo', type: 'string')
        params = parameters(foo: nil)

        assert(params.attribute?(:foo))
        assert_not(params.attribute?(:bar))
        assert_not(params.attribute?(nil))
      end

      def test_attributes
        operation.add_parameter('foo', type: 'string')
        params = parameters(foo: 'Value of foo')
        assert_equal({ 'foo' => 'Value of foo' }, params.attributes)
      end

      def test_additional_attributes
        operation.add_parameter('foo', type: 'string')
        operation.request_body = { additional_properties: { type: 'string' } }

        params = parameters(foo: 'Value of foo')
        assert_equal({}, params.additional_attributes)

        params = parameters(foo: 'Value of foo', bar: 'Value of bar')
        assert_equal({ 'bar' => 'Value of bar' }, params.additional_attributes)
      end

      # Validation

      def test_validates_parameters_against_schema
        operation.add_parameter('foo', type: 'string', existence: true)
        errors = Model::Errors.new

        # Good
        assert(parameters(foo: 'Value of foo').validate(errors))
        assert_predicate(errors, :empty?)

        # Bad
        assert_not(parameters(foo: '').validate(errors))
        assert(errors.added?(:foo, "can't be blank"))
      end

      def test_validates_nested_parameters_against_model
        parameter = operation.add_parameter('foo', type: 'object')
        parameter.schema.add_property('bar', type: 'string', existence: true)
        errors = Model::Errors.new

        # Good
        assert(parameters(foo: { 'bar' => 'Value of foo.bar' }).validate(errors))
        assert_predicate(errors, :empty?)

        # Bad
        assert_not(parameters(foo: {}).validate(errors))
        assert(errors.added?(:foo, "'bar' can't be blank"))
      end

      def test_detects_forbidden_parameters
        operation.add_parameter('foo', type: 'object')
        errors = Model::Errors.new

        # Good
        assert(parameters(strong: true).validate(errors))
        assert_predicate(errors, :empty?)

        %i[controller action format].each do |key|
          assert(parameters(**{ key => 'foo', ':strong' => true }).validate(errors))
          assert_predicate(errors, :empty?)
        end

        # Bad
        assert_not(parameters(bar: 'Value of bar', strong: true).validate(errors))
        assert(errors.added?(:base, "'bar' isn't allowed"))

        assert_not(parameters(foo: { bar: 'Value of foo.bar' }, strong: true).validate(errors))
        assert(errors.added?(:base, "'foo.bar' isn't allowed"))
      end

      def test_detects_forbidden_parameters_in_top_level_additional_properties
        operation.request_body = {
          type: 'object',
          additional_properties: {
            type: 'object',
            properties: {
              'bar' => { type: 'string' }
            }
          }
        }
        errors = Model::Errors.new

        # Good
        params = parameters(foo: { bar: '*' }, strong: true)
        assert(
          params.validate(errors) == true,
          "Expected #{params.inspect} to be valid."
        )
        assert_predicate(errors, :empty?)

        # Bad
        params = parameters(foo: { baz: '*' }, strong: true)
        assert(
          params.validate(errors) == false,
          "Expected #{params.inspect} to be invalid."
        )
        assert(errors.added?(:base, "'foo.baz' isn't allowed"))
      end

      def test_detects_forbidden_parameters_in_nested_additional_properties
        operation.request_body = {
          type: 'object',
          properties: {
            'foo' => {
              type: 'object',
              additional_properties: {
                type: 'object',
                properties: {
                  'bar' => { type: 'string' }
                }
              }
            }
          }
        }
        errors = Model::Errors.new

        # Good
        params = parameters(foo: { bar: { bar: '*' } }, strong: true)
        assert(
          params.validate(errors) == true,
          "Expected #{params.inspect} to be valid."
        )
        assert_predicate(errors, :empty?)

        # Bad
        params = parameters(foo: { bar: { baz: '*' } }, strong: true)
        assert(
          params.validate(errors) == false,
          "Expected #{params.inspect} to be invalid."
        )
        assert(errors.added?(:base, "'foo.bar.baz' isn't allowed"))
      end

      private

      def definitions
        @definitions ||= Meta::Definitions.new
      end

      def operation
        @operation ||= definitions.add_operation('operation')
      end

      def parameters(headers: {}, query_parameters: {}, strong: false, **params)
        query_parameters = query_parameters.deep_stringify_keys

        Parameters.new(
          ActionController::Parameters.new(
            **query_parameters,
            **params.deep_stringify_keys
          ),
          ActionDispatch::Request.new(
            headers: headers,
            query_parameters: query_parameters
          ),
          definitions.find_operation,
          strong: strong
        )
      end
    end
  end
end
