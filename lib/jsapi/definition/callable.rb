# frozen_string_literal: true

require_relative 'callable/symbol_evaluator'
require_relative 'callable/symbol_sequence_evaluator'

module Jsapi
  module Definition
    module Callable
      class << self
        def from(arg)
          raise ArgumentError, "argument can't be blank" if arg.blank?

          return arg if arg.respond_to?(:call) # e.g. a Proc

          symbols = Array.wrap(arg).flat_map do |symbol|
            next symbol if symbol.is_a?(Symbol)

            symbol.to_s.split('.')
          end.map(&:to_sym)

          return SymbolEvaluator.new(symbols.first) if symbols.one?

          SymbolSequenceEvaluator.new(*symbols)
        end
      end
    end
  end
end
