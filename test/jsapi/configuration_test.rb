# frozen_string_literal: true

require 'test_helper'

module Jsapi
  class ConfigurationTest < Minitest::Test
    def test_pathname
      Rails.stub(:root, nil) do
        assert_nil(Jsapi.configuration.pathname)
      end
      Rails.stub(:root, Pathname.new('/rails')) do
        pathname = Jsapi.configuration.pathname
        assert_equal(Pathname.new('/rails/jsapi/api_defs'), pathname)

        pathname = Jsapi.configuration.pathname('foo.rb')
        assert_equal(Pathname.new('/rails/jsapi/api_defs/foo.rb'), pathname)

        pathname = Jsapi.configuration.pathname('foo', 'bar.rb')
        assert_equal(Pathname.new('/rails/jsapi/api_defs/foo/bar.rb'), pathname)
      end
    end
  end
end
