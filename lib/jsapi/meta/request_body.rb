# frozen_string_literal: true

require_relative 'request_body/base'
require_relative 'request_body/reference'
require_relative 'request_body/wrapper'

module Jsapi
  module Meta
    module RequestBody
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
