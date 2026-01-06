# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          class BearerTest < Minitest::Test
            def test_token
              credentials = Bearer.new("Bearer #{Base64.encode64('foo')}")
              assert_equal('foo', credentials.token)
            end

            def test_well_formed
              auth_param = Base64.encode64('foo')

              assert(
                Bearer.new("Bearer #{auth_param}").well_formed? == true,
                'Expected HTTP Bearer Authentication credentials created ' \
                "from \"Bearer #{auth_param}\" to be well formed."
              )
              [nil, '', 'Bearer', 'Bearer ', 'Basic Og==}'].each do |authorization|
                assert(
                  Bearer.new(authorization).well_formed? == false,
                  'Expected HTTP Bearer Authentication credentials created ' \
                  "from #{authorization.inspect} not to be well formed."
                )
              end
            end
          end
        end
      end
    end
  end
end
