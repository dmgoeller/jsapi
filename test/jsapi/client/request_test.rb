# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Client
    class RequestTest < Minitest::Test
      def test_standard_request
        assert_kind_of(
          Net::HTTP::Get,
          Request.new(
            URI('https://foo.bar'),
            operation(
              method: 'get',
              responses: {
                200 => {
                  content_type: 'application/json'
                }
              }
            )
          ).http_request
        )
      end

      def test_custom_request
        http_request = Request.new(
          URI('https://foo.bar'),
          operation(
            method: 'custom',
            responses: {
              200 => {}
            }
          )
        ).http_request

        assert_equal('custom', http_request.method)
        assert_not(http_request.request_body_permitted?)
        assert_not(http_request.response_body_permitted?)
      end

      def test_custom_request_with_body_allowed
        assert_predicate(
          Request.new(
            URI('https://foo.bar'),
            operation(
              method: 'custom',
              request_body: {
                type: 'object'
              },
              responses: {
                200 => {}
              }
            )
          ).http_request,
          :request_body_permitted?
        )
      end

      def test_custom_request_with_response_body_allowed
        assert_predicate(
          Request.new(
            URI('https://foo.bar'),
            operation(
              method: 'custom',
              responses: {
                200 => {
                  content_type: 'application/json',
                  type: 'object'
                }
              }
            )
          ).http_request,
          :response_body_permitted?
        )
      end

      # HTTP headers

      def test_http_header_defined_as_parameter
        operation = operation(
          method: 'head',
          parameters: {
            'X-Foo' => {
              in: 'header',
              type: 'string'
            }
          }
        )
        { nil => nil, '' => '', 'bar' => 'bar' }.each do |value, expected|
          %w[X-FOO X-Foo x-foo X_FOO X_Foo x_foo].each do |name|
            request = Request.new(URI('https://foo.bar'), operation)
            request[name] = value

            actual = request.http_request['x-foo']
            assert(
              actual == expected,
              "Expected HTTP header value for parameter #{name.inspect} set to " \
              "#{value.inspect} to be #{expected.inspect}, is: #{actual.inspect}"
            )
          end
          %w[X-FOO X-Foo x-foo].each do |name|
            request = Request.new(URI('https://foo.bar'), operation)
            request.headers[name] = value

            actual = request.http_request['x-foo']
            assert(
              actual == expected,
              "Expected HTTP header value for header #{name.inspect} set to " \
              "#{value.inspect} to be #{expected.inspect}, is: #{actual.inspect}"
            )
          end
        end
      end

      def test_http_header_defined_as_array_parameter
        operation = operation(
          method: 'head',
          parameters: {
            'X-Foo' => {
              in: 'header',
              type: 'array',
              items: {
                type: 'string'
              }
            }
          }
        )
        {
          nil => nil,
          '' => '',
          'bar' => 'bar',
          %w[bar] => 'bar',
          %w[bar baz] => 'bar,baz'
        }.each do |value, expected|
          %w[X-FOO X-Foo x-foo X_FOO X_Foo x_foo].each do |name|
            request = Request.new(URI('https://foo.bar'), operation)
            request[name] = value

            actual = request.http_request['x-foo']
            assert(
              actual == expected,
              "Expected HTTP header for parameter #{name.inspect} set to " \
              "#{value.inspect} to be #{expected.inspect}, is: #{actual.inspect}"
            )
          end
          %w[X-FOO X-Foo x-foo].each do |name|
            request = Request.new(URI('https://foo.bar'), operation)
            request.headers[name] = value

            actual = request.http_request['x-foo']
            assert(
              actual == expected,
              "Expected HTTP header for header #{name.inspect} set to " \
              "#{value.inspect} to be #{expected.inspect}, is: #{actual.inspect}"
            )
          end
        end
      end

      def test_http_header_not_defined_as_parameter
        %w[X-FOO X-Foo x-foo].each do |name|
          request = Request.new(URI('https://foo.bar'), operation)
          request.headers[name] = 'bar'

          actual = request.http_request['x-foo']
          assert(
            actual == 'bar',
            "Expected HTTP header value assigned to #{name.inspect} header " \
            "to be \"bar\", is: #{actual.inspect}"
          )
        end
      end

      def test_parameter_takes_precedence_over_header
        operation = operation(
          method: 'head',
          parameters: {
            'x-foo' => {
              in: 'header',
              type: 'string'
            }
          }
        )
        request = Request.new(URI('https://foo.bar'), operation)
        request.headers['x-foo'] = 'bar'
        assert_equal('bar', request.http_request['x-foo'])

        request['x-foo'] = 'baz'
        assert_equal('baz', request.http_request['x-foo'])
      end

      # Path

      def test_path
        assert_equal(
          '/api/foo',
          Request.new(
            URI('https://foo.bar/api'),
            operation(method: 'head', path: 'foo')
          ).http_request.path
        )
      end

      def test_substitution_of_path_variables
        operation = operation(
          method: 'head',
          path: 'foos/{foo_id}/bars/{bar_id}',
          parameters: {
            'foo_id' => {
              type: 'string',
              in: 'path'
            },
            'bar_id' => {
              type: 'string',
              in: 'path'
            }
          }
        )
        # Valid request
        assert_equal(
          '/foos/1/bars/2',
          Request.new(
            URI('https://foo.bar'),
            operation,
            params: { foo_id: 1, bar_id: 2 }
          ).http_request.path
        )

        # Invalid request
        error = assert_raises(RequestError) do
          assert_equal(
            '/foos/{foo_id}/bars/{bar_id}',
            Request.new(
              URI('https://foo.bar'),
              operation
            ).http_request.path
          )
        end
        assert_equal('"{foo_id}" cannot be substituted', error.message)
      end

      # Query string

      def test_query_string
        operation = operation(
          method: 'head',
          parameters: {
            'foo' => {
              type: 'string',
              in: 'query',
              existence: true
            },
            'bar' => {
              type: 'string',
              in: 'query'
            }
          }
        )
        # Valid requests
        assert_equal(
          'foo=baz',
          Request.new(
            URI('https://foo.bar'),
            operation,
            params: { foo: 'baz' }
          ).http_request.uri.query
        )
        assert_equal(
          'bar=bat&foo=baz',
          Request.new(
            URI('https://foo.bar'),
            operation,
            params: { foo: 'baz', bar: 'bat' }
          ).http_request.uri.query
        )

        # Invalid request
        error = assert_raises(RequestError) do
          Request.new(
            URI('https://foo.bar'),
            operation,
            params: { bar: 'baz' }
          ).http_request.uri.query
        end
        assert_equal("foo can't be nil", error.message)
      end

      def test_query_string_with_nested_parameters
        operation = operation(
          method: 'head',
          parameters: {
            'foo' => {
              properties: {
                'bar' => {
                  properties: {
                    'baz' => {
                      type: 'string'
                    }
                  }
                }
              }
            }
          }
        )
        assert_equal(
          'foo%5Bbar%5D%5Bbaz%5D=bat', # => "foo[bar][baz]=bat"
          Request.new(
            URI('https://foo.bar'),
            operation,
            params: { foo: { bar: { baz: 'bat' } } }
          ).http_request.uri.query
        )

        [
          {},
          { foo: nil },
          { foo: {} },
          { foo: { bar: nil } },
          { foo: { bar: {} } },
          { foo: { bar: { baz: nil } } }
        ].each do |params|
          assert_empty(
            Request.new(
              URI('https://foo.bar'),
              operation,
              params: params
            ).http_request.uri.query,
            "Expected query string from #{params.inspect} to be empty"
          )
        end
      end

      # Body

      def test_body
        operation = operation(
          method: 'post',
          request_body: {
            contents: {
              'application/json' => {
                type: 'object',
                properties: {
                  'foo' => {
                    type: 'string',
                    existence: true
                  },
                  'bar' => {
                    type: 'string'
                  }
                }
              },
              'text/plain' => {
                type: 'string'
              }
            }
          }
        )
        # JSON request body with 'foo' and 'bar'
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'application/json'
        request.body = { foo: 'baz', bar: 'bat' }

        http_request = request.http_request
        assert_equal('POST', http_request.method)
        assert_equal('application/json', http_request.content_type)
        assert_equal('{"foo":"baz","bar":"bat"}', http_request.body)

        # JSON request body with 'foo' only
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'application/json'
        request.body = { foo: 'baz' }

        http_request = request.http_request
        assert_equal('POST', http_request.method)
        assert_equal('application/json', http_request.content_type)
        assert_equal('{"foo":"baz"}', http_request.body)

        # JSON request body on null
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'application/json'

        http_request = request.http_request
        assert_equal('null', http_request.body)

        # JSON request body on empty object
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'application/json'
        request.body = {}

        error = assert_raises(RequestError) do
          request.http_request
        end
        assert_equal("foo can't be nil", error.message)

        # Plain text request body
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'text/plain'
        request.body = 'Lorem ipsum'

        http_request = request.http_request
        assert_equal('POST', http_request.method)
        assert_equal('text/plain', http_request.content_type)
        assert_equal('Lorem ipsum', http_request.body)

        # Empty plain text request body
        request = Request.new(URI('https://foo.bar'), operation)
        request.content_type = 'text/plain'

        http_request = request.http_request
        assert_equal('', http_request.body)
      end

      def test_raises_an_error_if_content_type_is_invalid
        request = Request.new(
          URI('https://foo.bar'),
          operation(
            method: 'post',
            request_body: {
              contents: {
                'application/json' => {
                  properties: {
                    'foo' => { type: 'string' }
                  }
                }
              }
            }
          )
        )
        request.content_type = 'application'

        error = assert_raises(RequestError) { request.http_request }
        assert_equal('invalid media type: "application"', error.message)
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::Client::Request ' \
          'base_uri: https://foo.bar, ' \
          'operation: "default", ' \
          'headers: #<Jsapi::Client::Request::Headers>, ' \
          'parameters: #<Jsapi::Client::Request::Parameters>>',
          Request.new(URI('https://foo.bar'), operation).inspect
        )
      end

      private

      def operation(name = 'default', **keywords)
        Meta::Operation::Wrapper.new(
          Meta::Operation.new(name, **keywords),
          Meta::Definitions.new
        )
      end
    end
  end
end
