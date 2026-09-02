# frozen_string_literal: true

require_relative 'example/base'
require_relative 'example/builder'
require_relative 'example/reference'

module Jsapi
  module Meta
    module Example
      class << self
        # Creates a Base or Reference.
        def new(keywords = {})
          return Reference.new(keywords) if keywords.key?(:ref)

          Base.new(keywords)
        end
      end
    end
  end
end
