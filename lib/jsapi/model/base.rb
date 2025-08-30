# frozen_string_literal: true

module Jsapi
  module Model
    # The base API model.
    class Base
      extend ActiveModel::Naming

      # Overrides <code>ActiveModel::Naming#model_name</code> to support anonymous
      # model classes.
      def self.model_name
        @_model_name ||= begin
          # Prevent that ActiveModel::Name::new raises an error if this is an anonymous class
          klass = self
          klass = klass.superclass while klass.name.nil?

          # Adapted from ActiveModel::Naming#model_name
          namespace = klass.module_parents.detect do |n|
            n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
          end
          ActiveModel::Name.new(klass, namespace)
        end
      end

      extend ActiveModel::Translation
      include ActiveModel::Validations

      ##
      # :method: []
      # :call-seq: [](name)
      #
      # Returns the value assigned to +name+.

      ##
      # :method: additional_attributes
      #
      # Returns a hash containing the additional attributes.

      ##
      # :method: attribute?
      # :call-seq: attribute?(name)
      #
      # Returns +true+ if +name+ is present, +false+ otherwise.

      ##
      # :method: attributes
      #
      # Returns a hash containing all attributes.

      ##
      # :method: serializable_hash
      # :call-seq: serializable_hash(**options)
      #
      # Returns a hash containing serializable representations of all attributes.
      #
      # Possible options are:
      #
      # - +:only+ - The hash contains the given attributes only.
      # - +:except+ - The hash does not contain the given attributes.
      # - +:symbolize_names+ - If set to true, keys are symbols.
      # - +:jsonify_values+ - If set to true, values are converted by +as_json+.

      delegate :[], :additional_attributes, :attribute?, :attributes,
               :serializable_hash, to: :@nested

      validate :_nested_validity

      def initialize(nested)
        @nested = nested
      end

      def ==(other) # :nodoc:
        super || (
          self.class == other.class &&
          attributes == other.attributes
        )
      end

      # Overrides <code>ActiveModel::Validations#errors</code> to use Errors as error store.
      def errors
        @errors ||= Errors.new(self)
      end

      def inspect # :nodoc:
        "#<#{self.class.name}#{' ' if attributes.any?}" \
        "#{attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}>"
      end

      def respond_to_missing?(param1, _param2) # :nodoc:
        _attr_readers.key?(param1.to_s) ? true : super
      end

      private

      def _attr_readers
        @_attr_readers ||= attributes.transform_keys(&:underscore)
      end

      def _nested_validity
        @nested.validate(errors)
      end

      def method_missing(*args) # :nodoc:
        name = args.first.to_s
        _attr_readers.key?(name) ? _attr_readers[name] : super
      end
    end
  end
end
