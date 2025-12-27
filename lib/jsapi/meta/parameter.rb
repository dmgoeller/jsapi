# frozen_string_literal: true

require_relative 'parameter/base'
require_relative 'parameter/reference'
require_relative 'parameter/wrapper'

module Jsapi
  module Meta
    module Parameter
      include Model::Wrappable

      class << self
        # Creates a Base or Reference.
        def new(name, keywords = {})
          return Reference.new(keywords) if keywords.key?(:ref)

          Base.new(name, keywords)
        end
      end
    end
  end
end
