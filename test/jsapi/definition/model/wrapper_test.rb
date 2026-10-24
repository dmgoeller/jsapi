# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    module Model
      class WrapperTest < Minitest::Test
        def test_initialize_resolves_references
          wrapper = Wrapper.new(
            Dummy::Reference.new(ref: 'Foo'),
            Dummy::API.new(
              dummies: {
                'Foo' => model = Base.new
              }
            )
          )
          assert_equal(model, wrapper.__getobj__)
        end

        def test_equality_operator
          wrapper = Wrapper.new(
            model = Base.new,
            api = API.new
          )
          assert(wrapper == Wrapper.new(model, api))
          assert(wrapper != Wrapper.new(Base.new, api))
        end

        def test_inspect
          assert_equal(
            '#<Jsapi::Definition::Model::Wrapper #<Jsapi::Definition::Model::Base >>',
            Wrapper.new(Base.new, API.new).inspect
          )
        end
      end
    end
  end
end
