# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define top-level API components.
    class Definitions < Base
      ##
      # :method: base_path
      # :args: arg
      # Specifies the base path of the API.
      #
      #   base_path '/foo'
      #
      # See Meta::Definitions#base_path for further information.

      # Specifies a reusable callback.
      #
      #   callback 'foo' do
      #     operation '{$request.query.foo}', path: '/bar'
      #   end
      #
      # See Meta::Definitions#callbacks for further information.
      def callback(name, **keywords, &block)
        define('callback', name.inspect) do
          callback = @meta_model.add_callback(name, keywords)
          Callback.new(callback, &block) if block
        end
      end

      # Specifies the general default values for +type+.
      #
      #   default 'array', within_requests: [], within_responses: []
      #
      # See Meta::Definitions#defaults for further information.
      def default(type, **keywords, &block)
        define('default', type.inspect) do
          default = @meta_model.add_default(type, keywords)
          Base.new(default, &block) if block
        end
      end

      # Specifies a reusable example.
      #
      #   example '/foo', value: 'bar'
      #
      # See Meta::Definitions#examples for further information.
      def example(name, **keywords, &block)
        define('example', name.inspect) do
          example = @meta_model.add_example(name, keywords)
          Base.new(example, &block) if block
        end
      end

      ##
      # :method: external_docs
      # :args: **keywords, &block
      # Specifies the external documentation.
      #
      #   external_docs url: 'https://foo.bar'
      #
      # See Meta::Definitions#external_docs for further information.

      # Includes API definitions from +klasses+.
      def include(*klasses)
        klasses.each do |klass|
          @meta_model.include(klass.api_definitions)
        end
      end

      # Specifies a reusable header.
      #
      #   header 'foo', type: 'string'
      #
      # See Meta::Definitions#headers for further information.
      def header(name, **keywords, &block)
        define('header', name.inspect) do
          header = @meta_model.add_header(name, keywords)
          Base.new(header, &block) if block
        end
      end

      ##
      # :method: host
      # :args: arg
      # Specifies the host serving the API.
      #
      #   host 'foo.bar'
      #
      # See Meta::Definitions#host for further information.

      ##
      # :method: info
      # :args: **keywords, &block
      # Specifies general information about the API.
      #
      #   info title: 'foo', version: 1 do
      #     contact name: 'bar'
      #   end
      #
      # See Meta::Definitions#info for further information.

      # Specifies a reusable link.
      #
      #   link 'foo', operation_id: 'bar'
      #
      # See Meta::Definitions#links for further information.
      def link(name, **keywords, &block)
        define('link', name.inspect) do
          link = @meta_model.add_link(name, keywords)
          Base.new(link, &block) if block
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
          @meta_model.add_on_rescue(method || block)
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
      # See Meta::Definitions#operations for further information.
      def operation(name = nil, **keywords, &block)
        define('operation', name&.inspect) do
          operation_model = @meta_model.add_operation(name, keywords)
          Operation.new(operation_model, &block) if block
        end
      end

      # Specifies a reusable parameter.
      #
      #   parameter 'foo', type: 'string'
      #
      # See Meta::Definitions#parameters for further information.
      def parameter(name, **keywords, &block)
        define('parameter', name.inspect) do
          parameter_model = @meta_model.add_parameter(name, keywords)
          Parameter.new(parameter_model, &block) if block
        end
      end

      # Groups operations by path.
      #
      #   path 'api' do
      #     operation 'foo'
      #     operation 'bar'
      #   end
      #
      def path(name = nil, &block)
        define('path', name&.inspect) do
          path_model = @meta_model.add_path(name)
          Path.new(path_model, &block) if block
        end
      end

      # Specifies a reusable request body.
      #
      #   request_body 'foo', type: 'string'
      #
      # See Meta::Definitions#request_bodies for further information.
      def request_body(name, **keywords, &block)
        define('request_body', name.inspect) do
          request_body_model = @meta_model.add_request_body(name, keywords)
          RequestBody.new(request_body_model, &block) if block
        end
      end

      # Specifies the HTTP status code of an error response rendered when an exception of
      # any of +klasses+ has been raised.
      #
      #   rescue_from Jsapi::Controller::ParametersInvalid, with: 400
      #
      def rescue_from(*klasses, with: nil)
        klasses.each do |klass|
          @meta_model.add_rescue_handler({ error_class: klass, status: with })
        end
      end

      # Specifies a reusable response.
      #
      #   response 'Foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      #
      # See Meta::Definitions#responses for further information.
      def response(name, **keywords, &block)
        define('response', name.inspect) do
          response_model = @meta_model.add_response(name, keywords)
          Response.new(response_model, &block) if block
        end
      end

      # Specifies a reusable schema.
      #
      #   schema 'Foo' do
      #     property 'bar', type: 'string'
      #   end
      #
      # See Meta::Definitions#schemas for further information.
      def schema(name, **keywords, &block)
        define('schema', name.inspect) do
          schema_model = @meta_model.add_schema(name, keywords)
          Schema.new(schema_model, &block) if block
        end
      end

      ##
      # :method: scheme
      # :args: arg
      # Specifies a URI scheme supported by the API.
      #
      #   scheme 'https'
      #
      # See Meta::Definitions#schemes for further information.

      ##
      # :method: security_requirement
      # :args: **keywords, &block
      # Specifies a security requirement.
      #
      #   security_requirement do
      #     scheme 'basic_auth'
      #   end
      #
      # See Meta::Definitions#security_requirements for further information.

      # Specifies a security scheme.
      #
      #   security_scheme 'basic_auth', type: 'http', scheme: 'basic'
      #
      # See Meta::Definitions#security_schemes for further information.
      def security_scheme(name, **keywords, &block)
        define('security_scheme', name.inspect) do
          security_scheme = @meta_model.add_security_scheme(name, keywords)
          Base.new(security_scheme, &block) if block
        end
      end

      ##
      # :method: server
      # :args: **keywords, &block
      # Specifies a server providing the API.
      #
      #   server url: 'https://foo.bar/foo'
      #
      # See Meta::Definitions#servers for further information.

      ##
      # :method: tag
      # :args: **keywords, &block
      # Specifies a tag.
      #
      #   tag name: 'foo', description: 'description of foo'
      #
      # See Meta::Definitions#tags for further information.
    end
  end
end
