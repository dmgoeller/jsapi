# frozen_string_literal: true

module Jsapi
  module DSL
    class DefinitionsTest < Minitest::Test
      # #callback

      def test_callback
        callback = definitions do
          callback 'foo', operations: {
            'bar' => { description: 'Lorem ipsum' }
          }
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal('Lorem ipsum', callback.operation('bar').description)
      end

      def test_callback_with_block
        callback = definitions do
          callback 'foo' do
            operation 'bar', description: 'Lorem ipsum'
          end
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal('Lorem ipsum', callback.operation('bar').description)
      end

      def test_callback_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            callback 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at callback "foo")', error.message)
      end

      # #default

      def test_default
        default = definitions do
          default 'array', within_requests: []
        end.default('array')

        assert_predicate(default, :present?)
        assert_equal([], default.within_requests)
      end

      def test_default_with_block
        default = definitions do
          default 'array' do
            within_requests []
          end
        end.default('array')

        assert_predicate(default, :present?)
        assert_equal([], default.within_requests)
      end

      def test_default_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            default 'array', foo: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: foo (at default "array")', error.message)
      end

      # #example

      def test_example
        example = definitions do
          example 'foo', value: 'bar'
        end.example('foo')

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_with_block
        example = definitions do
          example 'foo' do
            value 'bar'
          end
        end.example('foo')

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_example_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            example 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at example "foo")', error.message)
      end

      # #include

      def test_include
        struct = Struct.new(:api_definitions)
        owner1 = struct.new(definitions { schema 'Foo' })
        owner2 = struct.new(definitions { include owner1 })

        schema = owner2.api_definitions.find_schema('Foo')
        assert_predicate(schema, :present?)
      end

      # #header

      def test_header
        header = definitions do
          header 'foo', description: 'Lorem ipsum'
        end.header('foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      def test_header_with_block
        header = definitions do
          header 'foo' do
            description 'Lorem ipsum'
          end
        end.header('foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      def test_header_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            header 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at header "foo")', error.message)
      end

      # #link

      def test_link
        link = definitions do
          link 'foo', description: 'Lorem ipsum'
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      def test_link_with_block
        link = definitions do
          link 'foo' do
            description 'Lorem ipsum'
          end
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      def test_link_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            link 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at link "foo")', error.message)
      end

      # #on_rescue

      def test_on_rescue
        on_rescue_callbacks = definitions do
          on_rescue :foo
        end.on_rescue_callbacks

        assert_equal(:foo, on_rescue_callbacks.first)
      end

      def test_on_rescue_with_block
        on_rescue_callbacks = definitions do
          on_rescue { |e| e }
        end.on_rescue_callbacks

        assert_instance_of(Proc, on_rescue_callbacks.first)
      end

      # #operation

      def test_named_operation
        operation = definitions do
          operation 'foo', description: 'Lorem ipsum'
        end.find_operation('foo')

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      def test_named_operation_with_block
        operation = definitions do
          operation 'foo' do
            description 'Lorem ipsum'
          end
        end.find_operation('foo')

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      def test_nameless_operation
        operation = definitions do
          operation description: 'Lorem ipsum'
        end.find_operation

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      def test_nameless_operation_with_block
        operation = definitions do
          operation do
            description 'Lorem ipsum'
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      def test_operation_raises_an_error_on_unsupported_keyword
        # Named operation
        error = assert_raises(Error) do
          definitions do
            operation 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at operation "foo")', error.message)

        # Nameless operation
        error = assert_raises(Error) do
          definitions do
            operation bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at operation)', error.message)
      end

      # #parameter

      def test_parameter
        parameter = definitions do
          parameter 'foo', description: 'Lorem ipsum'
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_with_block
        parameter = definitions do
          parameter 'foo' do
            description 'Lorem ipsum'
          end
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_parameter_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            parameter 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at parameter "foo")', error.message)
      end

      # #path

      def test_path
        paths = definitions do
          path 'foo'
        end.paths

        assert_equal(%w[/foo], paths.keys.map(&:to_s))
      end

      def test_root_path
        paths = definitions do
          path
        end.paths

        assert_equal(%w[/], paths.keys.map(&:to_s))
      end

      # #request_body

      def test_request_body
        request_body = definitions do
          request_body 'foo', description: 'Lorem ipsum'
        end.request_body('foo')

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_with_block
        request_body = definitions do
          request_body 'foo' do
            description 'Lorem ipsum'
          end
        end.request_body('foo')

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_request_body_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            request_body 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at request_body "foo")', error.message)
      end

      # #rescue_from

      def test_recue_from
        rescue_handlers = definitions do
          rescue_from StandardError, with: 500
        end.rescue_handlers

        assert_equal([500], rescue_handlers.map(&:status))
      end

      # #response

      def test_response
        response = definitions do
          response 'foo', description: 'Lorem ipsum'
        end.response('foo')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_with_block
        response = definitions do
          response 'foo' do
            description 'Lorem ipsum'
          end
        end.response('foo')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_response_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            response 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at response "foo")', error.message)
      end

      # #schema

      def test_schema
        schema = definitions do
          schema 'foo', description: 'Lorem ipsum'
        end.schema('foo')

        assert_predicate(schema, :present?)
        assert_equal('Lorem ipsum', schema.description)
      end

      def test_schema_with_block
        schema = definitions do
          schema 'foo' do
            description 'Lorem ipsum'
          end
        end.schema('foo')

        assert_predicate(schema, :present?)
        assert_equal('Lorem ipsum', schema.description)
      end

      def test_schema_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            schema 'foo', bar: 'Lorem ipsum'
          end
        end
        assert_equal('unsupported keyword: bar (at schema "foo")', error.message)
      end

      # #security_scheme

      def test_security_scheme
        security_scheme = definitions do
          security_scheme 'basic_auth', type: 'http',
                                        scheme: 'basic',
                                        description: 'Lorem ipsum'
        end.security_scheme('basic_auth')

        assert_predicate(security_scheme, :present?)
        assert_equal('Lorem ipsum', security_scheme.description)
      end

      def test_security_scheme_with_block
        security_scheme = definitions do
          security_scheme 'basic_auth', type: 'http', scheme: 'basic' do
            description 'Lorem ipsum'
          end
        end.security_scheme('basic_auth')

        assert_predicate(security_scheme, :present?)
        assert_equal('Lorem ipsum', security_scheme.description)
      end

      def test_security_scheme_raises_an_error_on_unsupported_keyword
        error = assert_raises(Error) do
          definitions do
            security_scheme 'basic_auth', type: 'http', foo: 'Lorem ipsum'
          end
        end
        assert_equal(
          'unsupported keyword: foo (at security_scheme "basic_auth")',
          error.message
        )
      end

      private

      def definitions(keywords = {}, &block)
        Meta::Definitions.new(keywords).tap do |definitions|
          Definitions.new(definitions, &block)
        end
      end
    end
  end
end
