# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          class BasicTest < Minitest::Test
            def test_user_and_password
              credentials = Basic.new("Basic #{Base64.encode64('foo:bar')}")
              assert_equal('foo', credentials.username)
              assert_equal('bar', credentials.password)
            end

            def test_well_formed
              auth_param = Base64.encode64('foo:bar')

              assert(
                Basic.new("Basic #{auth_param}").well_formed? == true,
                'Expected HTTP Basic Authentication credentials created ' \
                "from \"Basic #{auth_param}\" to be well formed."
              )
              [nil, '', 'Basic', 'Basic ', "Foo #{auth_param}"].each do |authorization|
                assert(
                  Basic.new(authorization).well_formed? == false,
                  'Expected HTTP Basic Authentication credentials created ' \
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
