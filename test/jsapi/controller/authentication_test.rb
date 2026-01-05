# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    class AuthenticationTest < Minitest::Test
      def test_authentication
        controller_class = controller_class_with_authentication do
          api_authenticate with: :authenticate

          api_authenticate 'api_key3' do |credentials|
            credentials.api_key == 'bar'
          end

          (1..3).each do |i|
            api_security_scheme(
              "api_key#{i}",
              type: 'api_key',
              in: 'header',
              name: "X-API-KEY-#{i}"
            )
          end

          api_security_requirement do
            scheme 'api_key1'
          end

          api_security_requirement do
            scheme 'api_key2'
            scheme 'api_key3'
          end

          private

          def authenticate(credentials)
            credentials.api_key == 'foo'
          end
        end

        # Requests with sufficient credentials
        assert(
          controller_class.new.instance_eval do
            request.headers['X-API-KEY-1'] = 'foo'
            api_authenticated?
          end == true
        )
        assert(
          controller_class.new.instance_eval do
            request.headers['X-API-KEY-2'] = 'foo'
            request.headers['X-API-KEY-3'] = 'bar'
            api_authenticated?
          end == true
        )
        # Request with insufficient credentials
        assert(
          controller_class.new.instance_eval do
            request.headers['X-API-KEY-2'] = 'foo'
            api_authenticated?
          end == false
        )
      end

      def test_authentication_succeeds_if_no_security_requirement_is_defined
        assert(
          controller_class_with_authentication.new.instance_eval do
            api_authenticated?
          end == true
        )
      end

      def test_authentication_fails_if_authentication_handler_is_absent
        controller_class = controller_class_with_authentication do
          api_security_scheme 'api_key', type: 'api_key', in: 'header', name: 'X-API-Key'
          api_security_requirement { scheme 'api_key' }
        end

        assert(
          controller_class.new.instance_eval do
            request.headers['X-API-Key'] = 'foo'
            api_authenticated?
          end == false
        )
      end

      def test_authentication_fails_if_security_scheme_is_not_defined
        controller_class = controller_class_with_authentication do
          api_authenticate { |*| true }
          api_security_requirement { scheme 'api_key' }
        end

        assert(
          controller_class.new.instance_eval do
            api_authenticated?
          end == false
        )
      end

      def test_authentication_fails_when_security_scheme_is_not_supported
        controller_class = controller_class_with_authentication do
          api_authenticate { |*| true }
          api_security_scheme 'basic_auth', type: 'mutual_tls'
          api_security_requirement { scheme 'basic_auth' }
        end
        assert(
          controller_class.new.instance_eval do
            api_authenticated?
          end == false
        )
      end

      def test_authentication_fails_when_credentials_are_not_well_formed
        controller_class = controller_class_with_authentication do
          api_authenticate { |*| true }
          api_security_scheme 'basic_auth', type: 'http', scheme: 'basic'
          api_security_requirement { scheme 'basic_auth' }
        end
        assert(
          controller_class.new.instance_eval do
            request.headers['Authorization'] = 'Basic'
            api_authenticated?
          end == false
        )
      end

      private

      def controller_class_with_authentication(&block)
        klass = Class.new(ActionController::API) do
          include Authentication
          include DSL
          include Methods

          api_operation 'foo'
        end
        klass.class_eval(&block) if block
        klass
      end
    end
  end
end
