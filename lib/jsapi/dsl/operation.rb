# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to define an API operation.
    class Operation < Base
      include SharedOperationMethods

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
      # See Definition::Operation#callbacks for further information.
      def callback(name = nil, **keywords, &block)
        define('callback', name&.inspect) do
          name = keywords[:ref] if name.nil?
          keywords = { ref: name } unless keywords.any? || block

          @definition.add_callback(name, keywords).tap do |callback_definition|
            Base.new(callback_definition, &block) if block
          end
        end
      end

      ##
      # :method: deprecated
      # :args: arg
      # Specifies whether the operation is marked as deprecated.
      #
      #   deprecated true

      ##
      # :method: external_docs
      # :args: **keywords, &block
      # Specifies the external documentation.
      #
      #    external_docs url: 'https://foo.bar/docs'
      #
      # See Definition::Operation#external_docs for further information.

      ##
      # :method: description
      # :args: arg
      # Specifies the description of the operation.

      # Specifies the HTTP method of the operation.
      #
      #   method 'post'
      #
      # See Definition::Operation#method for further information.
      #
      # Aliased as +http_method+.
      def method(arg)
        keyword(:method, arg)
      end

      ##
      # :method: path
      # :args: arg
      # Specifies the relative path of the operation.

      ##
      # :method: security_requirement
      # :args: **keywords, &block
      # Specifies a security requirement.
      #
      #   security_requirement do
      #     scheme 'basic_auth'
      #   end
      #
      # See Definition::Operation#security_requirements for further information.

      # :method: server
      # :args: arg
      # Specifies a server providing the operation.

      ##
      # :method: summary
      # :args: arg
      # Specifies the short description of the operation.

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
