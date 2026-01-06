# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          class BaseTest < Minitest::Test
            def test_auth_scheme_and_auth_param
              credentials = Base.new('Basic Og==')
              assert_equal('Basic', credentials.auth_scheme)
              assert_equal('Og==', credentials.auth_param)
            end

            def test_well_formed
              assert(
                Base.new('Basic Og==').well_formed? == true,
                'Expected HTTP Authentication credentials created from ' \
                '"Basic Og==" to be well formed.'
              )
              [nil, '', 'Basic', 'Basic '].each do |authorization|
                assert(
                  Base.new(authorization).well_formed? == false,
                  'Expected HTTP Authentication credentials created from ' \
                  "#{authorization.inspect} not to be well formed."
                )
              end
            end
          end
        end
      end
    end
  end
end
