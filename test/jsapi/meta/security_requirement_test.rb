# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class SecurityRequirementTest < Minitest::Test
      include TestHelper

      def test_empty_openapi_security_requirement_object
        assert_equal({}, SecurityRequirement.new.to_openapi)
      end

      def test_openapi_security_requirement_object_without_scopes
        security_requirement = SecurityRequirement.new(
          schemes: { 'foo' => nil, 'bar' => nil }
        )
        assert_equal(
          { 'foo' => [], 'bar' => [] },
          security_requirement.to_openapi
        )
      end

      def test_openapi_security_requirement_object_with_scopes
        security_requirement = SecurityRequirement.new(
          schemes: {
            'foo' => { scopes: %w[read:foo] },
            'bar' => { scopes: %w[read:bar] }
          }
        )
        assert_openapi_equal(
          {
            'foo' => %w[read:foo],
            'bar' => %w[read:bar]
          },
          security_requirement,
          nil
        )
      end
    end
  end
end
