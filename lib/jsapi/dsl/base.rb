# frozen_string_literal: true

module Jsapi
  module DSL
    class Base
      def initialize(meta_model, pathname = nil, parent: nil, &block)
        @meta_model = meta_model
        @pathname = pathname
        @parent = parent

        # Raise an error when pathname is attempted to be imported again
        if pathname && (ancestor = parent)
          while ancestor
            if ancestor.pathname == pathname
              raise Error, "Attempted #{pathname.to_path.inspect} to be imported again"
            end

            ancestor = ancestor.parent
          end
        end

        # Evaluate the file to be imported
        instance_eval(pathname.read, pathname.to_path) if pathname

        # Evaluate block
        if block
          if meta_model.reference?
            raise Error, "reference can't be specified together with a block"
          end

          instance_eval(&block)
        end
      end

      # Imports the file named +filename+ relative to +Jsapi.configation.path+.
      def import(filename)
        raise ArgumentError, "file name can't be blank" if filename.blank?

        pathname = Jsapi.configuration.pathname("#{filename}.rb")
        self.class.new(@meta_model, pathname, parent: self)
      end

      # Imports the file named +filename+ relative to the current file's path.
      def import_relative(filename)
        raise ArgumentError, "file name can't be blank" if filename.blank?

        pathname = (@pathname&.parent || Jsapi.configuration.pathname) + "#{filename}.rb"
        self.class.new(@meta_model, pathname, parent: self)
      end

      def respond_to_missing?(*args) # :nodoc:
        keyword?(args.first)
      end

      protected

      attr_reader :parent, :pathname

      private

      def define(*args, &block)
        result = block.call
        result.freeze_attributes if result.respond_to?(:freeze_attributes)
      rescue Error => e
        raise e.prepend_origin(args.compact.join(' '))
      rescue StandardError => e
        raise Error.new(e, args.compact.join(' ').presence)
      end

      def find_method(name)
        ["#{name}=", "add_#{name}"].find do |method|
          @meta_model.respond_to?(method)
        end
      end

      def keyword(name, *params, &block)
        method = find_method(name)
        raise "unsupported keyword: #{name}" unless method

        define(name) do
          @meta_model.public_send(method, *params).tap do |result|
            Base.new(result, &block) if block
          end
        end
      end

      def keyword?(name)
        find_method(name).present?
      end

      alias method_missing keyword
    end
  end
end
