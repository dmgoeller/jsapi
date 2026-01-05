# frozen_string_literal: true

module Jsapi
  module DSL
    class Path < Base
      include SharedOperationMethods

      ##
      # :method: description
      # :args: arg
      # Specifies the common description for all operations in this path.

      # Specifies an operation within this path.
      #
      #   operation 'foo' do
      #     parameter 'bar', type: 'string'
      #     response do
      #       property 'foo', type: 'string'
      #     end
      #   end
      #
      def operation(name = nil, **keywords, &block)
        define('operation', name&.inspect) do
          @meta_model.owner.add_operation(name, @meta_model.name, keywords)
                           .tap do |operation_model|
            Operation.new(operation_model, &block) if block
          end
        end
      end

      # Specifies a nested path.
      def path(name = nil, **keywords, &block)
        define('path', name&.inspect) do
          name = @meta_model.name + name.to_s

          @meta_model.owner.add_path(name, keywords).tap do |path_model|
            Path.new(path_model, &block) if block
          end
        end
      end

      # :method: server
      # :args: arg
      # Specifies a server providing all operations in this path.

      ##
      # :method: summary
      # :args: arg
      # Specifies the common summary for all operations in this path.

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
