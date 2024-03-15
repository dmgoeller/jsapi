# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Controller
    class BadRequestErrorTest < Minitest::Test
      def test_message
        Model::Errors.stub_any_instance(:full_messages, %w[foo]) do
          error = BadRequestError.new(Model::Errors.new)
          assert_equal('foo.', error.message)
        end

        Model::Errors.stub_any_instance(:full_messages, %w[foo bar]) do
          error = BadRequestError.new(Model::Errors.new)
          assert_equal('foo. bar.', error.message)
        end

        Model::Errors.stub_any_instance(:full_messages, %w[foo. bar.]) do
          error = BadRequestError.new(Model::Errors.new)
          assert_equal('foo. bar.', error.message)
        end
      end
    end
  end
end
