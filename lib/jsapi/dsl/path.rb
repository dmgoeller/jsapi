# frozen_string_literal: true

module Jsapi
  module DSL
    class Path < Base
      include CommonMethods

      # Specifies an operation within the current path.
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
    end
  end
end
