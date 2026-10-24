# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    class BaseTest < Minitest::Test
      def test_integration
        controller = Class.new(Base) do
          public :api

          api do
            operation 'foo'
          end
        end.new
        api = controller.api
        assert_predicate(api.find_operation('foo'), :present?)
      end
    end
  end
end
