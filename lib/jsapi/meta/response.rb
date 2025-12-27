# frozen_string_literal: true

require_relative 'response/base'
require_relative 'response/reference'
require_relative 'response/wrapper'

module Jsapi
  module Meta
    module Response
      include Model::Wrappable

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
