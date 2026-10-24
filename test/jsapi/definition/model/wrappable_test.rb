# frozen_string_literal: true

require 'test_helper'

require_relative 'dummy'

module Jsapi
  module Definition
    module Model
      class WrappableTest < Minitest::Test
        def test_wrap
          model = Dummy::Base.new
          wrapper = Dummy.wrap(model, API.new)

          assert_kind_of(Dummy::Wrapper, wrapper)
          assert_equal(model, wrapper.__getobj__)
        end

        def test_wrap_returns_nil_when_no_model_is_given
          assert_nil(Dummy.wrap(nil, API.new))
        end

        def test_wrap_prevents_double_wrapping
          wrapper = Dummy.wrap(Dummy::Base.new, API.new)
          assert(wrapper.equal?(Dummy.wrap(wrapper, nil)))
        end
      end
    end
  end
end
