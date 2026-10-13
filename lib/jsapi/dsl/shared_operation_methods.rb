# frozen_string_literal: true

module Jsapi
  module DSL
    module SharedOperationMethods
      # Specifies the model class to access top-level parameters by.
      #
      #   model Foo do
      #     def bar
      #       # ...
      #     end
      #   end
      #
      # +klass+ can be any subclass of Model::Base. If block is given, an anonymous
      # class is created that inherits either from +klass+ or Model::Base.
      #
      # See Meta::Operation#model and Meta::Path#model for further information.
      def model(klass = nil, &block)
        if block
          klass = Class.new(klass || Model::Base)
          klass.class_eval(&block)
        end
        @meta_model.model = klass
      end

      # Specifies a parameter.
      #
      #   parameter 'foo', type: 'string'
      #
      #   parameter 'foo', type: 'object' do
      #     property 'bar', type: 'string'
      #   end
      #
      # Refers a resuable parameter if the +:ref+ keyword is specified.
      #
      #   parameter ref: 'foo'
      #
      # Refers the reusable parameter with the same name if neither any
      # keywords nor a block is specified.
      #
      #   parameter 'foo'
      #
      # See Meta::Operation#parameters and Meta::Path#parameters for further
      # information.
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
      # :call-seq:
      #   request_body(**keywords, &block)
      #   request_body(name)
      #
      # Specifies a request body.
      #
      #   request_body type: 'object' do
      #     property 'foo', type: 'string'
      #   end
      #
      # Refers a resuable request body if the +:ref+ keyword is specified.
      #
      #   request_body ref: 'foo'
      #
      # Refers the reusable request body with the same name if neither any
      # keywords nor a block is specified.
      #
      #   request_body 'foo'
      #
      # See Meta::Operation#request_body and Meta::Path#request_body for
      # further information.
      def request_body(name = nil, **keywords, &block)
        define('request body') do
          raise Error, "name can't be specified together with keywords or a block" \
          if name && (keywords.any? || block)

          keywords = { ref: name } if name
          @meta_model.request_body = keywords

          @meta_model.request_body.tap do |request_body|
            RequestBody.new(request_body, &block) if block
          end
        end
      end

      ##
      # :call-seq:
      #   response(status = nil, **keywords, &block)
      #   response(status, name)
      #   response(name)
      #
      # Specifies a response.
      #
      #   response 200, type: 'object' do
      #     property 'foo', type: 'string'
      #   end
      #
      # The default status is <code>"default"</code>.
      #
      # Refers a resuable response if the +:ref+ keyword is specified.
      #
      #   response 200, ref: 'foo'
      #
      # Refers the reusable response with the same name if neither any
      # keywords nor a block is specified.
      #
      #   response 'foo'
      #
      # See Meta::Operation#responses and Meta::Path#responses for further
      # information.
      def response(status = nil, name = nil, **keywords, &block)
        define('response', status&.inspect) do
          if keywords.none? && !block
            status, name = nil, status unless name
            keywords = { ref: name }
          elsif name
            raise Error, "name can't be specified together with keywords or a block"
          end

          @meta_model.add_response(status, keywords).tap do |response_model|
            Response.new(response_model, &block) if block
          end
        end
      end

      ##
      # :method: tag
      # :args: name
      # Specifies a tag.
      #
      #   tag 'foo'
    end
  end
end
