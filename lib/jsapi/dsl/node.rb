# frozen_string_literal: true

module Jsapi
  module DSL
    class Node
      def self.scope(name)
        define_method(name) do |**keywords, &block|
          _define(name) do
            Node.new(_meta_model, "#{name}_", **keywords, &block)
          end
        end
      end

      def initialize(meta_model, prefix = nil, **keywords, &block)
        @_meta_model = meta_model
        @_prefix = prefix

        meta_model.merge!(keywords.transform_keys { |key| "#{prefix}#{key}" }) if keywords.any?
        instance_eval(&block) if block
      end

      def respond_to_missing?(*args) # :nodoc:
        _keyword?(args.first)
      end

      private

      attr_reader :_meta_model

      def _define(*args, &block)
        block.call
      rescue Error => e
        raise e.prepend_origin(args.compact.join(' '))
      rescue StandardError => e
        raise Error.new(e, args.compact.join(' ').presence)
      end

      def _eval(model, klass = Node, &block)
        return unless block

        if model.reference?
          raise Error, 'reference cannot be specified together with a block'
        end

        klass.new(model, &block)
      end

      def _find_method(name)
        ["#{@_prefix}#{name}=", "add_#{@_prefix}#{name}"].find do |method|
          _meta_model.respond_to?(method)
        end
      end

      def _keyword(name, *params, &block)
        method = _find_method(name)
        raise "unsupported method: #{name}" unless method

        _define(name) do
          value = _meta_model.public_send(method, *params)
          _eval(value, &block)
        end
      end

      def _keyword?(name)
        _find_method(name).present?
      end

      def method_missing(*args, &block)
        _keyword(*args, &block)
      end
    end
  end
end
