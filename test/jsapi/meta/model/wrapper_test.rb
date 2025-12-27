# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Model
      class WrapperTest < Minitest::Test
        def test_equality_operator
          wrapper = Wrapper.new(
            model = Base.new,
            definitions = Definitions.new
          )
          assert(wrapper == Wrapper.new(model, definitions))
          assert(wrapper != Wrapper.new(Base.new, definitions))
        end

        def test_inspect
          assert_equal(
            '#<Jsapi::Meta::Model::Wrapper #<Jsapi::Meta::Model::Base >>',
            Wrapper.new(Base.new, Definitions.new).inspect
          )
        end
      end
    end
  end
end
