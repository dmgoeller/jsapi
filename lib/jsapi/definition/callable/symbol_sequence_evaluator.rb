# frozen_string_literal: true

module Jsapi
  module Definition
    module Callable
      class SymbolSequenceEvaluator
        attr_reader :symbols

        def initialize(*symbols)
          @symbols = symbols
          @callables = symbols.map { |symbol| SymbolEvaluator.new(symbol) }
        end

        def inspect # :nodoc:
          "#<#{self.class.name} #{@symbols.inspect}>"
        end

        # Evaluates the symbols in sequence starting within the context of +object+.
        def call(object)
          @callables.each do |callable|
            object = callable.call(object)
            break if object.nil?
          end
          object
        end
      end
    end
  end
end
