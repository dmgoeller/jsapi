# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      class AttributesTest < Minitest::Test
        include Attributes

        def test_try_modify_attribute
          result = try_modify_attribute!(:foo)
          assert_nil(result)
          assert_attribute_changed(:foo)
        rescue FrozenError => _e
          assert(false, 'Expected no FrozenError to be raised.')
        end

        def test_try_modify_attribute_with_block
          result = try_modify_attribute!(:foo) { 'bar' }
          assert_equal('bar', result)
          assert_attribute_changed(:foo)
        rescue FrozenError => _e
          assert(false, 'Expected no FrozenError to be raised.')
        end

        def test_try_modify_attribute_raises_an_error_when_attributes_are_frozen
          freeze_attributes

          error = assert_raises(FrozenError) do
            try_modify_attribute!(:foo)
          end
          assert_equal(
            "can't modify frozen Jsapi::Meta::Model::AttributesTest",
            error.message
          )
        end

        protected

        def attribute_changed(name)
          @changed_attribute = name
        end

        private

        def assert_attribute_changed(name)
          assert(@changed_attribute == name, "Expected #{name} to be changed.")
        end
      end
    end
  end
end
