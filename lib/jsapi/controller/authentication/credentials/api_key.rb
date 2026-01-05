# frozen_string_literal: true

module Jsapi
  module Controller
    module Authentication
      module Credentials
        # API key credentials
        class APIKey
          attr_reader :api_key

          def initialize(api_key)
            @api_key = api_key
          end

          # Returns true if the API key is well formed.
          def well_formed?
            api_key.present?
          end
        end
      end
    end
  end
end
