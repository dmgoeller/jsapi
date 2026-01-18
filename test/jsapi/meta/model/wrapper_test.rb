# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Model
      class WrapperTest < Minitest::Test
        class DummyReference < Reference
          def self.name
            'Dummy::Reference'
          end
        end

        class DummyDefinitions
          def initialize(dummies:)
            @dummies = dummies
          end

          def find_dummy(name)
            @dummies[name]
          end
        end

        def test_initialize_resolves_references
          wrapper = Wrapper.new(
            DummyReference.new(ref: 'foo'),
            DummyDefinitions.new(
              dummies: {
                'foo' => model = Base.new
              }
            )
          )
          assert_equal(model, wrapper.__getobj__)
        end

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
