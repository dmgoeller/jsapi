# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    class LinkTest < Minitest::Test
      def test_new
        link = Link.new
        assert_kind_of(Link::Base, link)
      end

      def test_new_reference
        link = Link.new(ref: 'foo')
        assert_kind_of(Link::Reference, link)
      end
    end
  end
end
