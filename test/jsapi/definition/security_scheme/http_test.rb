# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    module SecurityScheme
      class HTTPTest < Minitest::Test
        def test_new_basic_scheme
          security_scheme = HTTP.new(scheme: 'basic')
          assert_kind_of(HTTP::Basic, security_scheme)
        end

        def test_new_bearer_scheme
          security_scheme = HTTP.new(scheme: 'bearer')
          assert_kind_of(HTTP::Bearer, security_scheme)
        end

        def test_new_other_scheme
          security_scheme = HTTP.new(scheme: 'digest')
          assert_kind_of(HTTP::Other, security_scheme)
          assert_equal('digest', security_scheme.scheme)
        end
      end
    end
  end
end
