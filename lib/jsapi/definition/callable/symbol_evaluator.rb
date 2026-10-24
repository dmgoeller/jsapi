# frozen_string_literal: true

module Jsapi
  module Definition
    module Callable
      class SymbolEvaluator
        attr_reader :symbol

        def initialize(symbol)
          @symbol = symbol
          @keys = [@symbol, @symbol.to_s]
        end

        def inspect # :nodoc:
          "#<#{self.class.name} #{@symbol.inspect}>"
        end

        # Evaluates the symbol within the context of +object+.
        def call(object)
          if object.respond_to?(@symbol)
            object.public_send(@symbol)
          elsif object.respond_to?(:[]) && object.respond_to?(:key?)
            @keys.each { |key| return object[key] if object.key?(key) }
            nil
          end
        end
      end
    end
  end
end
