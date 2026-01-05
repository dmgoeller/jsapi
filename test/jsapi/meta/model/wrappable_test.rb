# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Model
      class WrappableTest < Minitest::Test
        class Dummy < Base
          include Wrappable
          class Wrapper < Model::Wrapper; end
        end

        def test_wrap
          model = Dummy.new
          wrapper = Dummy.wrap(model, Definitions.new)

          assert_kind_of(Dummy::Wrapper, wrapper)
          assert_equal(model, wrapper.__getobj__)
        end

        def test_wrap_resolves_references
          model = Dummy.new
          wrapper = Dummy.wrap(
            Class.new do
              def initialize(model)
                @model = model
              end

              def resolve(*)
                @model
              end
            end.new(model),
            Definitions.new
          )
          assert_kind_of(Dummy::Wrapper, wrapper)
          assert_equal(model, wrapper.__getobj__)
        end

        def test_wrap_returns_nil_when_no_model_is_given
          assert_nil(Dummy.wrap(nil, Definitions.new))
        end

        def test_wrap_prevents_double_wrapping
          wrapper = Dummy.wrap(Dummy.new, Definitions.new)
          assert(wrapper.equal?(Dummy.wrap(wrapper, nil)))
        end
      end
    end
  end
end
