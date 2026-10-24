# frozen_string_literal: true

require_relative 'header/base'
require_relative 'header/reference'

module Jsapi
  module Definition
    module Header
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
