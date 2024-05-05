# frozen_string_literal: true

require_relative 'link/base'
require_relative 'link/reference'

module Jsapi
  module Meta
    module OpenAPI
      module Link
        class << self
          # Creates a link or a link reference.
          def new(keywords = {})
            return Reference.new(keywords) if keywords.key?(:ref)

            Base.new(keywords)
          end
        end
      end
    end
  end
end
