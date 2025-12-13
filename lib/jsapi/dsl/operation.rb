# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define an API operation.
    class Operation < Base

      # Specifies a callback.
      #
      #   callback 'foo' do
      #     operation '{$request.query.bar}'
      #   end
      #
      # Refers a resuable callback if the `:ref` keyword is specified.
      #
      #   callback ref: 'foo'
      #
      # Refers the reusable callback object with the same name if neither any
      # keywords nor a block is specified.
      #
      #   callback 'foo'
      #
      # See Meta::Operation#callbacks for further information.
      def callback(name = nil, **keywords, &block)
        define('callback', name&.inspect) do
          name = keywords[:ref] if name.nil?
          keywords = { ref: name } unless keywords.any? || block

          @meta_model.add_callback(name, keywords).tap do |callback_model|
            Base.new(callback_model, &block) if block
          end
        end
      end

      ##
      # :method: deprecated
      # :args: arg
      # Specifies whether or not the operation is deprecated.
      #
      #   deprecated true

      ##
      # :method: external_docs
      # :args: **keywords, &block
      # Specifies the external documentation.
      #
      #    external_docs url: 'https://foo.bar/docs'
      #
      # See Meta::Operation#external_docs for further information.

      ##
      # :method: description
      # :args: arg
      # Specifies the description of the operation.

      # Specifies the HTTP verb of the operation.
      #
      #   method 'post'
      #
      # See Meta::Operation#method for further information.
      def method(arg)
        keyword(:method, arg)
      end

      # Defines the model class to access top-level parameters by.
      #
      #   model Foo do
      #     def bar
      #       # ...
      #     end
      #   end
      #
      # +klass+ can be any subclass of Model::Base. If block is given, an anonymous
      # class is created that inherits either from +klass+ or Model::Base.
      def model(klass = nil, &block)
        if block
          klass = Class.new(klass || Model::Base)
          klass.class_eval(&block)
        end
        @meta_model.model = klass
      end

      # Specifies a parameter
      #
      #   parameter 'foo', type: 'string'
      #
      #   parameter 'foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      #
      # Refers a resuable parameter if the `:ref` keyword is specified.
      #
      #   parameter ref: 'foo'
      #
      # Refers the reusable parameter with the same name if neither any keywords
      # nor a block is specified.
      #
      #   parameter 'foo'
      #
      # See Meta::Operation#parameters for further information.
      def parameter(name = nil, **keywords, &block)
        define('parameter', name&.inspect) do
          name = keywords[:ref] if name.nil?
          keywords = { ref: name } unless keywords.any? || block

          @meta_model.add_parameter(name, keywords).tap do |parameter_model|
            Parameter.new(parameter_model, &block) if block
          end
        end
      end

      ##
      # :method: path
      # :args: arg
      # Specifies the relative path of the operation.

      # Specifies the request body.
      #
      #   request_body type: 'object' do
      #     property 'foo', type: 'string'
      #   end
      #
      # Refers a resuable request body if the `:ref` keyword is specified.
      #
      #   request_body ref: 'foo'
      #
      # Refers the reusable request body with the same name if neither any
      # keywords nor a block is specified.
      #
      #   request_body 'foo'
      #
      # See Meta::Operation#request_body for further information.
      def request_body(**keywords, &block)
        define('request body') do
          @meta_model.request_body = keywords

          @meta_model.request_body.tap do |request_body|
            RequestBody.new(request_body, &block) if block
          end
        end
      end

      # Specifies a response.
      #
      #   response 200, type: 'object' do
      #     property 'foo', type: 'string'
      #   end
      #
      # The default status is <code>"default"</code>.
      #
      # Refers a resuable response if the `:ref` keyword is specified.
      #
      #   response 200, ref: 'foo'
      #
      # Refers the reusable response with the same name if neither any keywords
      # nor a block is specified.
      #
      #   response 'foo'
      #
      # Raises an Error if name is specified together with keywords or a block.
      #
      # See Meta::Operation#responses for further information.
      def response(status_or_name = nil, name = nil, **keywords, &block)
        define('response', status_or_name&.inspect) do
          raise Error, "name can't be specified together with keywords " \
                       'or a block' if name && (keywords.any? || block)

          if keywords.any? || block
            status = status_or_name
          else
            status = status_or_name if name
            keywords = { ref: name || status_or_name }
          end
          @meta_model.add_response(status, keywords).tap do |response_model|
            Response.new(response_model, &block) if block
          end
        end
      end

      ##
      # :method: security_requirement
      # :args: **keywords, &block
      # Specifies a security requirement.
      #
      #   security_requirement do
      #     scheme 'basic_auth'
      #   end
      #
      # See Meta::Operation#security_requirements for further information.

      ##
      # :method: summary
      # :args: arg
      # Specifies the short summary of the operation.

      ##
      # :method: tag
      # :args: name
      # Adds a tag.
      #
      #   tag 'foo'

      ##
      # :method: tags
      # :args: names
      # Specifies all tags at once.
      #
      #   tags %w[foo bar]
    end
  end
end
