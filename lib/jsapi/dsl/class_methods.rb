# frozen_string_literal: true

module Jsapi
  module DSL
    module ClassMethods
      # Specifies the base path of the API.
      #
      #   api_base_path '/foo'
      #
      def api_base_path(arg)
        api_definitions { base_path(arg) }
      end

      # Specifies a reusable callback.
      #
      #   api_callback 'onFoo' do
      #     operation '{$request.query.foo}', path: '/bar'
      #   end
      #
      def api_callback(name, **keywords, &block)
        api_definitions { callback(name, **keywords, &block) }
      end

      # Specifies the general default values for +type+.
      #
      #   api_default 'array', within_requests: [], within_responses: []
      #
      def api_default(type, **keywords, &block)
        api_definitions { default(type, **keywords, &block) }
      end

      # Returns the API definitions associated with the current class. Adds additional
      # definitions when any keywords or a block is specified.
      #
      #   api_definitions base_path: '/foo' do
      #     operation 'bar'
      #   end
      def api_definitions(**keywords, &block)
        unless defined? @api_definitions
          @api_definitions = Meta::Definitions.new(
            owner: self,
            parent: superclass.try(:api_definitions)
          )
          if (name = try(:name))
            pathname = Jsapi.configuration.pathname(
              name.deconstantize.split('::').map(&:underscore),
              "#{name.demodulize.delete_suffix('Controller').underscore}.rb"
            )
            Definitions.new(@api_definitions, pathname) if pathname&.file?
          end
        end
        @api_definitions.merge!(keywords) if keywords.any?
        Definitions.new(@api_definitions, &block) if block

        @api_definitions
      end

      # Specifies a reusable example.
      #
      #   example 'foo', value: 'bar'
      #
      def api_example(name, **keywords, &block)
        api_definitions { example(name, **keywords, &block) }
      end

      # Specifies the external documentation.
      #
      #   api_external_docs url: 'https://foo.bar'
      #
      def api_external_docs(**keywords, &block)
        api_definitions { external_docs(**keywords, &block) }
      end

      # Specifies a reusable header.
      #
      #   api_header 'foo', type: 'string'
      #
      def api_header(name, **keywords, &block)
        api_definitions { header(name, **keywords, &block) }
      end

      # Specifies the host serving the API.
      #
      #   api_host 'foo.bar'
      #
      def api_host(arg)
        api_definitions { host(arg) }
      end

      # Imports the file named +filename+ relative to +Jsapi.configation.path+.
      def api_import(filename)
        api_definitions { import(filename) }
      end

      # Includes API definitions from +klasses+.
      def api_include(*klasses)
        api_definitions { include(*klasses) }
      end

      # Specifies general information about the API.
      #
      #   api_info title: 'Foo', version: '1' do
      #     contact name: 'bar'
      #   end
      def api_info(**keywords, &block)
        api_definitions { info(**keywords, &block) }
      end

      # Specifies a reusable link.
      #
      #   api_link 'foo', operation_id: 'bar'
      #
      def api_link(name, **keywords, &block)
        api_definitions { link(name, **keywords, &block) }
      end

      # Registers a callback to be called when rescuing an exception.
      #
      #   api_on_rescue :foo
      #
      #   api_on_rescue do |error|
      #     # ...
      #   end
      def api_on_rescue(method = nil, &block)
        api_definitions { on_rescue(method, &block) }
      end

      # Specifies an operation.
      #
      #   api_operation 'foo', path: '/foo' do
      #     parameter 'bar', type: 'string'
      #     response do
      #       property 'foo', type: 'string'
      #     end
      #   end
      #
      # +name+ can be +nil+ if the controller handles one operation only.
      def api_operation(name = nil, **keywords, &block)
        api_definitions { operation(name, **keywords, &block) }
      end

      # Specifies a reusable parameter.
      #
      #   api_parameter 'foo', type: 'string'
      #
      def api_parameter(name, **keywords, &block)
        api_definitions { parameter(name, **keywords, &block) }
      end

      # Groups operations by path.
      #
      #   api_path 'api' do
      #     operation 'foo'
      #     operation 'bar'
      #   end
      #
      def api_path(name, **keywords, &block)
        api_definitions { path(name, **keywords, &block) }
      end

      # Defines a reusable request body.
      #
      #   api_request_body 'foo', type: 'string'
      #
      def api_request_body(name, **keywords, &block)
        api_definitions { request_body(name, **keywords, &block) }
      end

      # Specifies the HTTP status code of an error response rendered when an
      # exception of any of +klasses+ has been raised.
      #
      #   api_rescue_from Jsapi::Controller::ParametersInvalid, with: 400
      #
      def api_rescue_from(*klasses, with: nil)
        api_definitions { rescue_from(*klasses, with: with) }
      end

      # Specifies a reusable response.
      #
      #   api_response 'Foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      def api_response(name, **keywords, &block)
        api_definitions { response(name, **keywords, &block) }
      end

      # Specifies a reusable schema.
      #
      #   api_schema 'Foo' do
      #     property 'bar', type: 'string'
      #   end
      def api_schema(name, **keywords, &block)
        api_definitions { schema(name, **keywords, &block) }
      end

      # Specifies a URI scheme supported by the API.
      #
      #   api_scheme 'https'
      #
      def api_scheme(arg)
        api_definitions { scheme(arg) }
      end

      # Specifies a security requirement.
      #
      #   api_security_requirement do
      #     scheme 'basic_auth'
      #   end
      #
      def api_security_requirement(**keywords, &block)
        api_definitions { security_requirement(**keywords, &block) }
      end

      # Specifies a security scheme.
      #
      #   api_security_scheme 'basic_auth', type: 'http', scheme: 'basic'
      #
      def api_security_scheme(name, **keywords, &block)
        api_definitions { security_scheme(name, **keywords, &block) }
      end

      # Specifies a server providing the API.
      #
      #   api_server url: 'https://foo.bar/foo'
      #
      def api_server(**keywords, &block)
        api_definitions { server(**keywords, &block) }
      end

      # Specifies a tag.
      #
      #   api_tag name: 'foo', description: 'description of foo'
      #
      def api_tag(**keywords, &block)
        api_definitions { tag(**keywords, &block) }
      end
    end
  end
end
