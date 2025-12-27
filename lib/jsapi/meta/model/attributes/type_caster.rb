# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      module Attributes
        class TypeCaster
          STRING_CASTER = ->(arg) { arg&.to_s } # :nodoc:

          SYMBOL_CASTER = ->(arg) { # :nodoc:
            return if arg.nil?

            arg = arg.to_s unless arg.respond_to?(:to_sym)
            arg.to_sym
          }

          # Creates a new type caster for +klass+.
          def initialize(klass = nil, name: 'value', values: nil)
            klass = Object if klass.nil?
            @caster =
              case klass.name
              when 'String'
                STRING_CASTER
              when 'Symbol'
                SYMBOL_CASTER
              else
                ->(arg) {
                  return arg if arg.is_a?(klass)
                  return klass.from(arg) if klass.respond_to?(:from)
                  return klass.new if arg.nil?

                  klass.new(arg)
                }
              end
            @values = values
            @name = name
          end

          # Casts +value+.
          #
          # Raises an InvalidArgumentError if the (casted) value is invalid.
          def cast(value)
            casted_value = @caster.call(value)
            return casted_value unless @values&.exclude?(casted_value)

            raise InvalidArgumentError.new(@name, casted_value, valid_values: @values)
          end
        end
      end
    end
  end
end
