# frozen_string_literal: true

module Jsapi
  module DSL
    class Path < Base
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

      # Specifies a parameter applicable for all operations in this path.
      #
      #   parameter 'foo', type: 'string'
      #
      # See Meta::Path#parameters for further information.
      def parameter(name, **keywords, &block)
        define('parameter', name.inspect) do
          @meta_model.add_parameter(name, keywords).tap do |parameter_model|
            Parameter.new(parameter_model, &block) if block
          end
        end
      end

      # Specifies a nested path.
      def path(name = nil, &block)
        define('path', name&.inspect) do
          @meta_model.owner.add_path(@meta_model.name + name.to_s).tap do |path_model|
            Path.new(path_model, &block) if block
          end
        end
      end
    end
  end
end
