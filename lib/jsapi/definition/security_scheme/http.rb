# frozen_string_literal: true

require_relative 'http/basic'
require_relative 'http/bearer'
require_relative 'http/other'

module Jsapi
  module Definition
    module SecurityScheme
      module HTTP
        class << self
          # Creates a new \HTTP authentication scheme.
          def new(keywords = {})
            scheme = keywords[:scheme] || 'basic'

            case scheme.to_s
            when 'basic'
              HTTP::Basic.new(keywords.except(:scheme))
            when 'bearer'
              HTTP::Bearer.new(keywords.except(:scheme))
            else
              HTTP::Other.new(keywords)
            end
          end
        end
      end
    end
  end
end
