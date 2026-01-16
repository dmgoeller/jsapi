# frozen_string_literal: true

module Jsapi
  module Controller
    module Methods
      module Callbacks
        # Represents a callback to be triggered.
        class Callback
          # The method or +Proc+ to be called.
          attr_reader :method_or_proc

          # Creates a callback that executes +method_or_proc+.
          #
          # The following options can be specified:
          #
          # - +:if+ - The conditions under which the callback is triggered only.
          # - +:unless+ - The conditions under which the callback isn't triggered.
          # - +:only+ - The operations on which the callback is triggered only.
          # - +:except+ - The operations on which the callback isn't triggered.
          #
          # +:if+ and +:unless+ can be a symbol, a +Proc+ or an array of symbols
          # and +Proc+s.
          def initialize(method_or_proc, **options)
            @method_or_proc = method_or_proc

            @if, @unless =
              %i[if unless].map do |key|
                value = options[key]
                Array.wrap(value) if value
              end

            @only, @except =
              %i[only except].map do |key|
                value = options[key]
                Array.wrap(value).map(&:to_s) if value
              end
          end

          def inspect # :nodoc:
            "#<#{self.class} #{@method_or_proc.inspect}#{
              {
                if: @if,
                unless: @unless,
                only: @only,
                except: @except
              }.filter_map do |key, value|
                next if value.nil?

                value = value.sole if value.one?
                ", #{key}: #{value.inspect}"
              end.join
            }>"
          end

          # Returns true if and only if the callback must not be triggered on
          # +controller+ and +operation_name+.
          def skip_on?(controller, operation_name)
            operation_name = operation_name.to_s

            @only&.exclude?(operation_name) ||
              @except&.include?(operation_name) ||
              @if&.any? { |condition| !evaluate(condition, controller) } ||
              @unless&.any? { |condition| evaluate(condition, controller) } ||
              false
          end

          private

          def evaluate(condition, context)
            if condition.is_a?(Proc)
              context.instance_exec(&condition)
            else
              context.send(condition)
            end
          end
        end
      end
    end
  end
end
