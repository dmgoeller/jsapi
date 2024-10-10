# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class CallbackTest < Minitest::Test
      def test_new_model
        callback = Callback.new
        assert_kind_of(Callback::Model, callback)
      end

      def test_new_reference
        callback = Callback.new(ref: 'foo')
        assert_kind_of(Callback::Reference, callback)
      end
    end
  end
end
