# frozen_string_literal: true

require 'test_helper'

require_relative '../dummy_session'

module Jsapi
  module Client
    module Session
      module Test
        class ClassMethodsTest < Minitest::Test
          def test_spy_stubs_new
            DummySession.spy do
              session = DummySession.new
              assert_kind_of(Spy, session)
            end
          end

          def test_spy_restores_new
            DummySession.spy {}
            assert_kind_of(DummySession, DummySession.new)
          end

          def test_spy_returns_result_from_block
            assert_same(value = 'foo', DummySession.spy { value })
          end

          def test_spy_returns_nil_if_no_block_is_given
            assert_nil(DummySession.spy)
          end
        end
      end
    end
  end
end
