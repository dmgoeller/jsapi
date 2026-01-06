# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          class BasicTest < Minitest::Test
            def test_username_and_password
              credentials = Basic.new("Basic #{Base64.encode64('foo:bar')}")
              assert_equal('foo', credentials.username)
              assert_equal('bar', credentials.password)
            end

            def test_empty_username_and_password
              credentials = Basic.new("Basic #{Base64.encode64(':')}")
              assert_equal('', credentials.username)
              assert_equal('', credentials.password)
            end

            def test_well_formed
              %w[: foo: :bar foo:bar].each do |auth_param|
                assert(
                  Basic.new("Basic #{Base64.encode64(auth_param)}").well_formed? == true,
                  'Expected HTTP Basic Authentication credentials created ' \
                  "from \"Basic #{auth_param}\" to be well formed."
                )
              end
              [nil, '', 'Basic', 'Basic ', 'Bearer Og=='].each do |authorization|
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
