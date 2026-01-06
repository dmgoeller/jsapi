# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        class APIKeyTest < Minitest::Test
          def test_api_key
            credentials = APIKey.new('foo')
            assert_equal('foo', credentials.api_key)
          end

          def test_well_formed
            ['', 'foo'].each do |api_key|
              assert(
                APIKey.new(api_key).well_formed? == true,
                'Expected API key credentials created from ' \
                "#{api_key.inspect} to be well formed."
              )
            end
            assert(
              APIKey.new(nil).well_formed? == false,
              'Expected API key credentials created from ' \
              'nil not to be well formed.'
            )
          end
        end
      end
    end
  end
end

