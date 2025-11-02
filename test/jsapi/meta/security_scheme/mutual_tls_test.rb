# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module SecurityScheme
      class MutualTLSTest < Minitest::Test
        include OpenAPITestHelper

        def test_minimal_openapi_security_scheme_object
          security_scheme = MutualTLS.new

          each_openapi_version do |version|
            assert_openapi_equal(
              if version < OpenAPI::V3_1
                nil
              else
                { type: 'mutualTLS' }
              end,
              security_scheme,
              version
            )
          end
        end
      end
    end
  end
end
