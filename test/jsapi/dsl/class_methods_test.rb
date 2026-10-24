# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module DSL
    class ClassMethodsTest < Minitest::Test
      # #api

      def test_api
        base_klass = Class.new do
          extend ClassMethods
        end
        klass = Class.new(base_klass)

        base_api = base_klass.api
        assert_equal(base_klass, base_api.owner)
        assert_nil(base_api.parent)

        api = klass.api
        assert_equal(klass, api.owner)
        assert_equal(base_api, api.parent)
      end

      def test_api_with_keywords
        api = Class.new do
          extend ClassMethods
          api base_path: '/foo'
        end.api

        assert_equal('/foo', api.base_path.to_s)
      end

      def test_api_with_block
        api = Class.new do
          extend ClassMethods
          api do
            base_path '/foo'
          end
        end.api

        assert_equal('/foo', api.base_path.to_s)
      end

      def test_loads_api_definition_from_file
        configuration = Minitest::Mock.new
        pathname = Minitest::Mock.new

        configuration.expect(:pathname, pathname, [[], 'foo.rb'])
        pathname.expect(:file?, true)
        pathname.expect(:read, "base_path '/foo'")
        pathname.expect(:to_path, '/foo.rb')

        Jsapi.stub(:configuration, configuration) do
          api = Class.new do
            extend ClassMethods

            def self.name
              'Foo'
            end
          end.api

          assert_equal('/foo', api.base_path.to_s)
        end
      end

      def test_api_is_aliased_as_api_definitions
        klass = Class.new do
          extend ClassMethods
        end
        assert_same(klass.api, klass.api_definitions)
      end

      # #api_base_path

      def test_api_base_path
        base_path = api do
          api_base_path '/foo'
        end.base_path

        assert_equal('/foo', base_path.to_s)
      end

      # #api_callback

      def test_api_callback
        callback = api do
          api_callback 'foo', expressions: {
            '{$url}' => {
              operations: {
                'get' => { description: 'Lorem ipsum' }
              }
            }
          }
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal(
          'Lorem ipsum',
          callback.expression('{$url}')&.operation('get')&.description
        )
      end

      def test_api_callback_with_block
        callback = api do
          api_callback 'foo' do
            expression '{$url}' do
              operation 'get', description: 'Lorem ipsum'
            end
          end
        end.callback('foo')

        assert_predicate(callback, :present?)
        assert_equal(
          'Lorem ipsum',
          callback.expression('{$url}')&.operation('get')&.description
        )
      end

      # #api_default

      def test_api_default
        default = api do
          api_default 'array', within_responses: []
        end.default('array')

        assert_predicate(default, :present?)
        assert_equal([], default.within_responses)
      end

      def test_api_default_with_block
        default = api do
          api_default 'array' do
            within_responses []
          end
        end.default('array')

        assert_predicate(default, :present?)
        assert_equal([], default.within_responses)
      end

      # #api_example

      def test_api_example
        example = api do
          api_example 'foo', value: 'bar'
        end.example('foo')

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      def test_api_example_with_block
        example = api do
          api_example 'foo' do
            value 'bar'
          end
        end.example('foo')

        assert_predicate(example, :present?)
        assert_equal('bar', example.value)
      end

      # #api_external_docs

      def test_api_external_docs
        external_docs = api do
          api_external_docs description: 'Lorem ipsum'
        end.external_docs

        assert_predicate(external_docs, :present?)
        assert_equal('Lorem ipsum', external_docs.description)
      end

      def test_api_external_docs_with_block
        external_docs = api do
          api_external_docs do
            description 'Lorem ipsum'
          end
        end.external_docs

        assert_predicate(external_docs, :present?)
        assert_equal('Lorem ipsum', external_docs.description)
      end

      # #api_header

      def test_api_header
        header = api do
          api_header 'foo', description: 'Lorem ipsum'
        end.header('foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      def test_api_header_with_block
        header = api do
          api_header 'foo' do
            description 'Lorem ipsum'
          end
        end.header('foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      # #api_host

      def test_api_host
        host = api do
          api_host 'foo.bar'
        end.host

        assert_equal('foo.bar', host)
      end

      # #api_import

      def test_api_import
        configuration = Minitest::Mock.new
        pathname = Minitest::Mock.new

        configuration.expect(:pathname, pathname, %w[foo.rb])
        pathname.expect(:read, "base_path '/foo'")
        pathname.expect(:to_path, '')

        definitions = Jsapi.stub(:configuration, configuration) do
          api do
            api_import 'foo'
          end
        end
        assert_equal('/foo', definitions.base_path.to_s)
      end

      # #api_include

      def test_api_include
        foo_class = Class.new do
          extend ClassMethods
          api_schema 'foo'
        end
        bar_class = Class.new do
          extend ClassMethods
          api_include foo_class
        end

        schema = bar_class.api.find_schema('foo')
        assert_predicate(schema, :present?)
      end

      # #api_info

      def test_api_info
        info = api do
          api_info title: 'foo'
        end.info

        assert_predicate(info, :present?)
        assert_equal('foo', info.title)
      end

      def test_api_info_with_block
        info = api do
          api_info do
            title 'foo'
          end
        end.info

        assert_predicate(info, :present?)
        assert_equal('foo', info.title)
      end

      # #api_link

      def test_api_link
        link = api do
          api_link 'foo', description: 'Lorem ipsum'
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      def test_api_link_with_block
        link = api do
          api_link 'foo' do
            description 'Lorem ipsum'
          end
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      # #api_on_rescue

      def test_api_on_rescue
        on_rescue_callbacks = api do
          api_on_rescue :foo
        end.on_rescue_callbacks

        assert_equal(:foo, on_rescue_callbacks.first)
      end

      def test_api_on_rescue_with_block
        on_rescue_callbacks = api do
          api_on_rescue { |e| e }
        end.on_rescue_callbacks

        assert_instance_of(Proc, on_rescue_callbacks.first)
      end

      # #api_operation

      def test_api_operation
        operation = api do
          api_operation 'foo', description: 'Lorem ipsum'
        end.operation('foo')

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      def test_api_operation_with_block
        operation = api do
          api_operation 'foo' do
            description 'Lorem ipsum'
          end
        end.operation('foo')

        assert_predicate(operation, :present?)
        assert_equal('Lorem ipsum', operation.description)
      end

      # #api_parameter

      def test_api_parameter
        parameter = api do
          api_parameter 'foo', description: 'Lorem ipsum'
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      def test_api_parameter_with_block
        parameter = api do
          api_parameter 'foo' do
            description 'Lorem ipsum'
          end
        end.parameter('foo')

        assert_predicate(parameter, :present?)
        assert_equal('Lorem ipsum', parameter.description)
      end

      # #api_path

      def test_api_path
        operation = api do
          api_path 'foo' do
            operation path: 'bar'
          end
        end.find_operation

        assert_predicate(operation, :present?)
        assert_equal('/foo/bar', operation.full_path.to_s)
      end

      # #api_request_body

      def test_api_request_body
        request_body = api do
          api_request_body 'foo', description: 'Lorem ipsum'
        end.request_body('foo')

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      def test_api_request_body_with_block
        request_body = api do
          api_request_body 'foo' do
            description 'Lorem ipsum'
          end
        end.request_body('foo')

        assert_predicate(request_body, :present?)
        assert_equal('Lorem ipsum', request_body.description)
      end

      # #api_rescue_from

      def test_api_rescue_from
        rescue_handler = api do
          api_rescue_from StandardError
        end.rescue_handler_for(StandardError.new)

        assert_predicate(rescue_handler, :present?)
      end

      # #api_response

      def test_api_response
        response = api do
          api_response 'foo', description: 'Lorem ipsum'
        end.response('foo')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      def test_api_response_with_block
        response = api do
          api_response 'foo' do
            description 'Lorem ipsum'
          end
        end.response('foo')

        assert_predicate(response, :present?)
        assert_equal('Lorem ipsum', response.description)
      end

      # #api_schema

      def test_api_schema
        schema = api do
          api_schema 'foo', description: 'Lorem ipsum'
        end.schema('foo')

        assert_predicate(schema, :present?)
        assert_equal('Lorem ipsum', schema.description)
      end

      def test_api_schema_with_block
        schema = api do
          api_schema 'foo' do
            description 'Lorem ipsum'
          end
        end.schema('foo')

        assert_predicate(schema, :present?)
        assert_equal('Lorem ipsum', schema.description)
      end

      # #api_scheme

      def test_api_scheme
        schemes = api do
          api_scheme 'https'
        end.schemes

        assert_equal(%w[https], schemes)
      end

      # #api_security_requirement

      def test_api_security_requirement
        security_requirements = api do
          api_security_requirement schemes: { 'basic_auth' => [] }
        end.security_requirements

        assert_predicate(security_requirements, :one?)
        assert_equal([], security_requirements.first.schemes['basic_auth'].scopes)
      end

      def test_api_security_requirement_with_block
        security_requirements = api do
          api_security_requirement do
            scheme 'basic_auth'
          end
        end.security_requirements

        assert_predicate(security_requirements, :one?)
        assert_equal([], security_requirements.first.schemes['basic_auth'].scopes)
      end

      # #api_security_scheme

      def test_api_security_scheme
        security_scheme = api do
          api_security_scheme 'basic_auth', type: 'http',
                                            scheme: 'basic',
                                            description: 'Lorem ipsum'
        end.security_scheme('basic_auth')

        assert_predicate(security_scheme, :present?)
        assert_equal('Lorem ipsum', security_scheme.description)
      end

      def test_api_security_scheme_with_block
        security_scheme = api do
          api_security_scheme 'basic_auth', type: 'http', scheme: 'basic' do
            description 'Lorem ipsum'
          end
        end.security_scheme('basic_auth')

        assert_predicate(security_scheme, :present?)
        assert_equal('Lorem ipsum', security_scheme.description)
      end

      # #api_server

      def test_api_server
        servers = api do
          api_server url: 'https://foo.bar/foo'
        end.servers

        assert_predicate(servers, :one?)
        assert_equal('https://foo.bar/foo', servers.first.url)
      end

      def test_api_server_with_block
        servers = api do
          api_server do
            url 'https://foo.bar/foo'
          end
        end.servers

        assert_predicate(servers, :one?)
        assert_equal('https://foo.bar/foo', servers.first.url)
      end

      # #api_tag

      def test_api_tag
        tags = api do
          api_tag name: 'foo'
        end.tags

        assert_predicate(tags, :one?)
        assert_equal('foo', tags.first.name)
      end

      def test_api_tag_with_block
        tags = api do
          api_tag do
            name 'foo'
          end
        end.tags

        assert_predicate(tags, :one?)
        assert_equal('foo', tags.first.name)
      end

      private

      def api(&block)
        klass = Class.new do
          extend ClassMethods
        end
        klass.class_eval(&block)
        klass.api
      end
    end
  end
end
