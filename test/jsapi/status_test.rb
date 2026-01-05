# frozen_string_literal: true

require 'test_helper'

module Jsapi
  class StatusTest < Minitest::Test
    def test_from
      {
        [nil, 'default', Status::DEFAULT] => Status::DEFAULT,
        %w[1XX 1xx] => Status::Range::INFORMATIONAL,
        %w[2XX 2xx] => Status::Range::SUCCESS,
        %w[3XX 3xx] => Status::Range::REDIRECTION,
        %w[4XX 4xx] => Status::Range::CLIENT_ERROR,
        %w[5XX 5xx] => Status::Range::SERVER_ERROR,
        [200, '200', :ok] => Status::Code.new(200)
      }.each do |values, expected|
        values.each do |value|
          assert(
            expected == actual = Status.from(value),
            "Expected #{value.inspect} to be transformed " \
            "to #{expected.inspect}, is: #{actual.inspect}."
          )
        end
      end
    end

    def test_from_raises_an_error_on_invalid_value
      [0, '0', 'foo', ''].each do |value|
        assert_raises(ArgumentError) do
          Status.from(value)
        end
      end
    end
  end
end
