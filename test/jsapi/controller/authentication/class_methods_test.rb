# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    module Authentication
      class ClassMethodsTest < Minitest::Test
        def test_api_authenticate
          base = Class.new do
            extend ClassMethods
            api_authenticate with: :default_authenticate
          end
          klass = Class.new(base) do
            api_authenticate 'http_basic', with: :http_basic_authenticate
          end
          assert_equal(
            :http_basic_authenticate,
            klass._api_authentication_handler('http_basic')
          )
          assert_equal(
            :default_authenticate,
            klass._api_authentication_handler('other')
          )
        end

        def test_api_authenticate_with_block
          authentication_handler = Class.new do
            extend ClassMethods

            api_authenticate do |credentials|
              credentials
            end
          end._api_authentication_handler('http_basic')

          assert_equal('secret', authentication_handler.call('secret'))
        end

        def test_api_authenticate_raises_an_error_if_neither_with_nor_a_block_is_specified
          error = assert_raises(ArgumentError) do
            Class.new do
              extend ClassMethods
              api_authenticate
            end
          end
          assert_equal(
            'either the :with keyword argument or a block must be specified',
            error.message
          )
        end
      end
    end
  end
end
