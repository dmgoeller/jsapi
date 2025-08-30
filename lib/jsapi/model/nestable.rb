# frozen_string_literal: true

module Jsapi
  module Model
    module Nestable
      # Returns the value assigned to +name+.
      def [](name)
        raw_attributes[name&.to_s]&.value
      end

      # Returns a hash containing the additional attributes.
      def additional_attributes
        raw_additional_attributes.transform_values(&:value)
      end

      # Returns +true+ if +name+ is present, +false+ otherwise.
      def attribute?(name)
        raw_attributes.key?(name&.to_s)
      end

      # Returns a hash containing all attributes.
      def attributes
        raw_attributes.transform_values(&:value)
      end

      def inspect # :nodoc:
        "#<#{self.class.name} #{
          raw_attributes
            .merge('additional_attributes' => raw_additional_attributes)
            .map { |k, v| "#{k}: #{v.inspect}" }
            .join(', ')
        }>"
      end

      # Returns a hash containing serializable representations of all attributes.
      #
      # Possible options are:
      #
      # - +:only+ - The hash contains the given attributes only.
      # - +:except+ - The hash does not contain the given attributes.
      # - +:symbolize_names+ - If set to true, keys are symbols.
      # - +:jsonify_values+ - If set to true, values are converted by +as_json+.
      def serializable_hash(**options)
        options = options.dup
        except = options.delete(:except)&.map(&:to_s)
        only = options.delete(:only)&.map(&:to_s)
        symbolize_names = options[:symbolize_names] == true

        {}.tap do |hash|
          [raw_attributes, raw_additional_attributes].each do |attributes|
            attributes.each do |name, value|
              next if except&.include?(name) || only&.exclude?(name)

              name = name.to_sym if symbolize_names
              hash[name] = value.serializable_value(**options)
            end
          end
        end
      end

      private

      def validate_attributes(errors)
        [raw_attributes, raw_additional_attributes].compact.map do |attributes|
          attributes.map do |name, value|
            errors.nested(name) do
              next value.validate(errors) unless value.respond_to?(:model)
              next true if (model = value.model).valid?

              errors.merge!(model)
              false
            end
          end.all?
        end.all?
      end
    end
  end
end
