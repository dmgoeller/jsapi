# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define an \API.
    class API < Base
      ##
      # :method: base_path
      # :args: arg
      # Specifies the base path of the \API.
      #
      #   base_path '/foo'
      #
      # See Definition::API#base_path for further information.

      # Specifies a reusable callback.
      #
      #   callback 'foo' do
      #     operation '{$request.query.foo}', path: '/bar'
      #   end
      #
      # See Definition::API#callbacks for further information.
      def callback(name, **keywords, &block)
        define('callback', name.inspect) do
          @definition.add_callback(name, keywords).tap do |callback|
            Base.new(callback, &block) if block
          end
        end
      end

      # Specifies the general default values for +type+.
      #
      #   default 'array', within_requests: [], within_responses: []
      #
      # See Definition::API#defaults for further information.
      def default(type, **keywords, &block)
        define('default', type.inspect) do
          @definition.add_default(type, keywords).tap do |default|
            Base.new(default, &block) if block
          end
        end
      end

      # Specifies a reusable example.
      #
      #   example '/foo', value: 'bar'
      #
      # See Definition::API#examples for further information.
      def example(name, **keywords, &block)
        define('example', name.inspect) do
          @definition.add_example(name, keywords).tap do |example|
            Base.new(example, &block) if block
          end
        end
      end

      ##
      # :method: external_docs
      # :args: **keywords, &block
      # Specifies the external documentation.
      #
      #   external_docs url: 'https://foo.bar'
      #
      # See Definition::API#external_docs for further information.

      # Includes \API components from +klasses+.
      def include(*klasses)
        klasses.each do |klass|
          @definition.include(klass.api_definitions)
        end
      end

      # Specifies a reusable header.
      #
      #   header 'foo', type: 'string'
      #
      # See Definition::API#headers for further information.
      def header(name, **keywords, &block)
        define('header', name.inspect) do
          @definition.add_header(name, keywords).tap do |header|
            Base.new(header, &block) if block
          end
        end
      end

      ##
      # :method: host
      # :args: arg
      # Specifies the host serving the \API.
      #
      #   host 'foo.bar'
      #
      # See Definition::API#host for further information.

      ##
      # :method: info
      # :args: **keywords, &block
      # Specifies general information about the \API.
      #
      #   info title: 'foo', version: 1 do
      #     contact name: 'bar'
      #   end
      #
      # See Definition::API#info for further information.

      # Specifies a reusable link.
      #
      #   link 'foo', operation_id: 'bar'
      #
      # See Definition::API#links for further information.
      def link(name, **keywords, &block)
        define('link', name.inspect) do
          @definition.add_link(name, keywords).tap do |link|
            Base.new(link, &block) if block
          end
        end
      end

      # Registers a callback to be called when rescuing an exception.
      #
      #   on_rescue :foo
      #
      #   on_rescue do |error|
      #     # ...
      #   end
      def on_rescue(method = nil, &block)
        define('on_rescue') do
          @definition.add_on_rescue(method || block)
        end
      end

      # Specifies an operation.
      #
      #   operation 'foo', path: '/foo' do
      #     parameter 'bar', type: 'string'
      #     response do
      #       property 'foo', type: 'string'
      #     end
      #   end
      #
      # +name+ can be +nil+ if the controller handles one operation only.
      #
      # See Definition::API#operations for further information.
      def operation(name = nil, **keywords, &block)
        define('operation', name&.inspect) do
          @definition.add_operation(name, keywords).tap do |operation_definition|
            Operation.new(operation_definition, &block) if block
          end
        end
      end

      # Specifies a reusable parameter.
      #
      #   parameter 'foo', type: 'string'
      #
      # See Definition::API#parameters for further information.
      def parameter(name, **keywords, &block)
        define('parameter', name.inspect) do
          @definition.add_parameter(name, keywords).tap do |parameter_definition|
            Parameter.new(parameter_definition, &block) if block
          end
        end
      end

      # Groups operations by path.
      #
      #   path 'api' do
      #     operation 'foo'
      #     operation 'bar'
      #   end
      #
      def path(name = nil, **keywords, &block)
        define('path', name&.inspect) do
          @definition.add_path(name, keywords).tap do |path_definition|
            Path.new(path_definition, &block) if block
          end
        end
      end

      # Specifies a reusable request body.
      #
      #   request_body 'foo', type: 'string'
      #
      # See Definition::API#request_bodies for further information.
      def request_body(name, **keywords, &block)
        define('request_body', name.inspect) do
          @definition.add_request_body(name, keywords).tap do |request_body_definition|
            RequestBody.new(request_body_definition, &block) if block
          end
        end
      end

      # Specifies the status code of a response to be produced when an error of
      # any of +klasses+ has been raised.
      #
      #   rescue_from Jsapi::Controller::ParametersInvalid, with: 400
      #
      def rescue_from(*klasses, with: nil)
        klasses.each do |klass|
          @definition.add_rescue_handler(
            { error_class: klass, status_code: with }
          )
        end
      end

      # Specifies a reusable response.
      #
      #   response 'Foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      #
      # See Definition::API#responses for further information.
      def response(name, **keywords, &block)
        define('response', name.inspect) do
          @definition.add_response(name, keywords).tap do |response_definition|
            Response.new(response_definition, &block) if block
          end
        end
      end

      # Specifies a reusable schema.
      #
      #   schema 'Foo' do
      #     property 'bar', type: 'string'
      #   end
      #
      # See Definition::API#schemas for further information.
      def schema(name, **keywords, &block)
        define('schema', name.inspect) do
          @definition.add_schema(name, keywords).tap do |schema_definition|
            Schema.new(schema_definition, &block) if block
          end
        end
      end

      ##
      # :method: scheme
      # :args: arg
      # Specifies a URI scheme supported by the \API.
      #
      #   scheme 'https'
      #
      # See Definition::API#schemes for further information.

      ##
      # :method: security_requirement
      # :args: **keywords, &block
      # Specifies a security requirement.
      #
      #   security_requirement do
      #     scheme 'basic_auth'
      #   end
      #
      # See Definition::API#security_requirements for further information.

      # Specifies a security scheme.
      #
      #   security_scheme 'basic_auth', type: 'http', scheme: 'basic'
      #
      # See Definition::API#security_schemes for further information.
      def security_scheme(name, **keywords, &block)
        define('security_scheme', name.inspect) do
          @definition.add_security_scheme(name, keywords).tap do |security_scheme|
            Base.new(security_scheme, &block) if block
          end
        end
      end

      ##
      # :method: server
      # :args: **keywords, &block
      # Specifies a server providing the \API.
      #
      #   server url: 'https://foo.bar/foo'
      #
      # See Definition::API#servers for further information.

      ##
      # :method: tag
      # :args: **keywords, &block
      # Specifies a tag.
      #
      #   tag name: 'foo', description: 'description of foo'
      #
      # See Definition::API#tags for further information.
    end
  end
end
