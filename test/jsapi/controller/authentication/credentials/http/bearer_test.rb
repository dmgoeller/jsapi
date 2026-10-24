# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      module Credentials
        module HTTP
          class BearerTest < Minitest::Test
            def test_token
              credentials = Bearer.new('Bearer foo')
              assert_equal('foo', credentials.token)
            end
          end
        end
      end
    end
  end
end
