# frozen_string_literal: true

module Jsapi
  module Controller
    module Authentication
      module Credentials
        # Holds an API key.
        class APIKey
          # The API key as it was passed.
          attr_reader :api_key

          def initialize(api_key)
            @api_key = api_key
          end

          # Returns true if the API Key is not nil.
          def well_formed?
            !api_key.nil?
          end
        end
      end
    end
  end
end
