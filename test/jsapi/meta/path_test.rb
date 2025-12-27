# frozen_string_literal: true

require 'test_helper'

require_relative 'test_helper'

module Jsapi
  module Meta
    class PathTest < Minitest::Test
      include TestHelper

      def test_name
        path = Path.new('/foo', nil)
        assert_equal(Pathname.new('/foo'), path.name)
      end

      def test_add_parameter
        path = Path.new('/foo', nil)
        parameter = path.add_parameter('bar')
        assert(parameter.equal?(path.parameter('bar')))
      end

      def test_add_parameter_raises_an_error_when_frozen
        path = Path.new('/foo', nil)
        path.freeze_attributes

        assert_raises(Model::Attributes::FrozenError) do
          path.add_parameter('bar')
        end
      end

      def test_inspect
        path = Path.new('/foo', owner: Definitions.new)
        assert(path.inspect.exclude?('owner:'))
      end

      def test_notifies_owner_to_invalidate_path_attribute
        owner = Minitest::Mock.new
        path = Path.new('/foo', owner)

        owner.expect(:invalidate_path_attribute, nil, [path.name, :parameters])
        path.add_parameter('bar')

        owner.verify
      end
    end
  end
end
