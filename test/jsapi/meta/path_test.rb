# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class PathTest < Minitest::Test
      include OpenAPITestHelper

      def test_name
        path = Path.new('/foo', nil)
        assert_equal(Pathname.new('/foo'), path.name)
      end

      def test_add_parameters
        owner = Minitest::Mock.new
        path = Path.new('/foo', owner)

        owner.expect(:invalidate_path_parameters, nil, [path.name])

        parameter = path.add_parameter('bar')
        assert(parameter.equal?(path.parameter('bar')))

        owner.verify
      end
    end
  end
end
