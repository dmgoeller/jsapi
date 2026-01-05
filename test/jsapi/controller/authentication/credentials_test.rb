# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      class CredentialsTest < Minitest::Test
        # API keys

        def test_api_key_as_header
          credentials = Credentials.create(
            ActionDispatch::Request.new(
              headers: {
                'X-API-KEY' => 'foo'
              }
            ),
            Meta::SecurityScheme::APIKey.new(
              in: 'header',
              name: 'X-API-KEY'
            )
          )
          assert_kind_of(Credentials::APIKey, credentials)
          assert_equal('foo', credentials.api_key)
        end

        def test_api_key_as_query_parameter
          credentials = Credentials.create(
            ActionDispatch::Request.new(
              query_parameters: {
                'api-key' => 'foo'
              }
            ),
            Meta::SecurityScheme::APIKey.new(
              in: 'query',
              name: 'api-key'
            )
          )
          assert_kind_of(Credentials::APIKey, credentials)
          assert_equal('foo', credentials.api_key)
        end

        def test_api_key_on_other_location
          credentials = Credentials.create(
            ActionDispatch::Request.new,
            Meta::SecurityScheme::APIKey.new(
              in: 'cookie',
              name: 'apikey'
            )
          )
          assert_kind_of(Credentials::APIKey, credentials)
          assert_not(credentials.well_formed?)
        end

        # HTTP Authentication

        def test_http_basic
          credentials = Credentials.create(
            ActionDispatch::Request.new(
              headers: {
                'Authorization' => "Basic #{Base64.encode64('foo:bar')}"
              }
            ),
            Meta::SecurityScheme::HTTP::Basic.new
          )
          assert_kind_of(Credentials::HTTP::Basic, credentials)
          assert_equal('foo', credentials.username)
          assert_equal('bar', credentials.password)
        end

        def test_http_bearer
          credentials = Credentials.create(
            ActionDispatch::Request.new(
              headers: {
                'Authorization' => "Bearer #{Base64.encode64('foo')}"
              }
            ),
            Meta::SecurityScheme::HTTP::Bearer.new
          )
          assert_kind_of(Credentials::HTTP::Bearer, credentials)
          assert_equal('foo', credentials.token)
        end

        def test_other_http_auth_scheme
          credentials = Credentials.create(
            ActionDispatch::Request.new(
              headers: {
                'Authorization' => 'foo bar'
              }
            ),
            Meta::SecurityScheme::HTTP::Other.new
          )
          assert_kind_of(Credentials::HTTP::Base, credentials)
          assert_equal('foo', credentials.auth_scheme)
          assert_equal('bar', credentials.auth_param)
        end

        # Other

        def test_unsupported_security_scheme
          assert_nil(
            Credentials.create(ActionDispatch::Request.new, nil)
          )
        end
      end
    end
  end
end
