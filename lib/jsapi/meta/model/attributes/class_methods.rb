# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      module Attributes
        module ClassMethods
          DEFAULT_ARRAY = [].freeze
          DEFAULT_HASH = {}.freeze

          # Defines an attribute.
          def attribute(name, type = Object,
                        accessors: %i[add reader writer],
                        default: nil,
                        default_key: nil,
                        keys: nil,
                        values: nil)

            (@attribute_names ||= []) << name.to_sym

            instance_variable_name = "@#{name}"

            case type
            when Array
              # General default
              default ||= DEFAULT_ARRAY

              if accessors.include?(:add) || accessors.include?(:writer)
                singular_name = name.to_s.singularize
                add_method = "add_#{singular_name}"
                type_caster = TypeCaster.new(type.first, values: values, name: singular_name)

                # Attribute writer
                define_method("#{name}=") do |argument|
                  instance_variable_set(instance_variable_name, []).tap do
                    Array.wrap(argument).each { |element| send(add_method, element) }
                  end
                end if accessors.include?(:writer)

                # Add method
                define_method(add_method) do |argument = nil|
                  try_modify_attribute!(name) do
                    type_caster.cast(argument).tap do |casted_argument|
                      if instance_variable_defined?(instance_variable_name)
                        instance_variable_get(instance_variable_name)
                      else
                        instance_variable_set(instance_variable_name, [])
                      end << casted_argument
                    end
                  end
                end if accessors.include?(:add)
              end
            when Hash
              # General default
              default ||= DEFAULT_HASH

              singular_name = name.to_s.singularize
              key_type, value_type = type.first
              key_type_caster = TypeCaster.new(key_type, values: keys, name: 'key')

              # Lookup method
              define_method(singular_name) do |key = nil|
                key = default_key if key.to_s.empty?
                send(name)[key_type_caster.cast(key)]
              end if accessors.include?(:reader)

              if accessors.include?(:add) || accessors.include?(:writer)
                add_method = "add_#{singular_name}"
                value_type_caster = TypeCaster.new(value_type, values: values)

                # Attribute writer
                define_method("#{name}=") do |argument|
                  instance_variable_set(instance_variable_name, {}).tap do
                    Hash(argument).each { |key, value| send(add_method, key, value) }
                  end
                end if accessors.include?(:writer)

                # Add method
                define_method(add_method) do |key_or_value, value = nil|
                  try_modify_attribute!(name) do
                    if value.nil? && default_key
                      key = default_key
                      value = key_or_value
                    else
                      key = key_or_value
                      key = default_key if key.to_s.empty?
                    end
                    raise ArgumentError, "key can't be blank" if key.to_s.empty?

                    if instance_variable_defined?(instance_variable_name)
                      instance_variable_get(instance_variable_name)
                    else
                      instance_variable_set(instance_variable_name, {})
                    end[key_type_caster.cast(key)] = value_type_caster.cast(value)
                  end
                end if accessors.include?(:add)
              end
            else
              # Predicate method
              define_method("#{name}?") do
                value = instance_variable_get(instance_variable_name)
                value.nil? ? default || false : value
              end if values == [true, false] && accessors.include?(:reader)

              if accessors.include?(:writer)
                type_caster = TypeCaster.new(type, values: values, name: name)

                # Attribute writer
                define_method("#{name}=") do |argument = nil|
                  try_modify_attribute!(name) do
                    instance_variable_set(instance_variable_name, type_caster.cast(argument))
                  end
                end
              end
            end

            default = nil if default == :nil

            # Attribute reader
            define_method(name) do
              value = instance_variable_get(instance_variable_name)
              value.nil? ? default : value
            end if accessors.include?(:reader)
          end

          def attribute_names
            names = @attribute_names || []
            return names unless superclass.respond_to?(:attribute_names)

            superclass.attribute_names + names
          end
        end
      end
    end
  end
end
