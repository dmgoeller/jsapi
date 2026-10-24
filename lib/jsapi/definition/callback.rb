# frozen_string_literal: true

require_relative 'callback/base'
require_relative 'callback/reference'

module Jsapi
  module Definition
    module Callback
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
