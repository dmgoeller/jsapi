# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Media
    class RangeTest < Minitest::Test
      %i[from try_from].each do |method|
        define_method(:"test_#{method}_from_media_range_object") do
          media_range = Range.new('*', '*')
          assert(Range.public_send(method, media_range).equal?(media_range))
        end

        define_method(:"test_#{method}_string") do
          %w[* application].each do |type|
            %w[* json json-seq problem+json vnd.foo vnd.foo+json].each do |subtype|
              media_range = Range.public_send(method, "#{type}/#{subtype}")
              assert(
                media_range.type == type,
                "Expected type of #{media_range.inspect} to be #{type.inspect}."
              )
              assert(
                media_range.subtype == subtype,
                "Expected subtype of #{media_range.inspect} to be #{subtype.inspect}."
              )
            end
          end
        end
      end

      def test_from_raises_an_error_when_value_could_not_be_transformed
        [nil, '', '*', 'application'].each do |value|
          error = assert_raises(ArgumentError) do
            Range.from(value)
          end
          assert_equal("invalid media range: #{value.inspect}", error.message)
        end
      end

      def test_try_from_returns_nil_when_value_could_not_be_transformed
        [nil, '', '*', 'application'].each do |value|
          assert_nil(Range.try_from(value))
        end
      end

      def test_reduce
        {
          %w[application/json text/json] => %w[application/json text/json],
          %w[text/* text/json text/plain] => %w[text/*],
          %w[*/* text/* text/json] => %w[*/*]
        }.each do |media_ranges, expected|
          media_ranges.permutation.each do |arg|
            assert(
              Range.reduce(arg) == expected.map { |m| Range.from(m) },
              "Expected #{arg.inspect} to be reduced to #{expected.inspect}."
            )
          end
        end
      end

      def test_equality_operator
        media_range = Range.new('*', '*')

        assert(
          media_range == other = Range.new('*', '*'),
          "Expected #{other.inspect} to be equal to #{media_range.inspect}."
        )
        assert(
          media_range != other = Range.new('application', '*'),
          "Expected #{other.inspect} not to be equal to #{media_range.inspect}."
        )
        assert(
          media_range != other = Range.new('*', 'json'),
          "Expected #{other.inspect} not to be equal to #{media_range.inspect}."
        )
        assert(
          media_range != other = '*/*',
          "Expected #{other.inspect} not to be equal to #{media_range.inspect}."
        )
      end

      def test_comparison_operator
        assert(
          media_range = Range.new('text', '*') <
            other = Range.new('*', '*'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert(
          media_range = Range.new('text', 'plain') <
            other = Range.new('text', '*'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert(
          media_range = Range.new('text', 'json') <
            other = Range.new('text', 'plain'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert(
          media_range = Range.new('application', 'json') <
            other = Range.new('text', 'json'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert_nil(
          media_range = Range.new('application', 'json') <=>
            other = 'application/json',
          "Exptected #{other.inspect} to be not comparable to #{media_range.inspect}."
        )
      end

      def test_hash
        media_ranges = [
          Range.new('*', '*'),
          Range.new('text', '*'),
          Range.new('text', 'json')
        ]
        hash = media_ranges.index_with(&:to_s)

        assert_equal(media_ranges, hash.keys)
      end

      [['cover', 'be covered by'], ['match', 'match']].each do |name, verb_phrase|
        method = :"#{name}?"

        define_method(:"test_#{name}") do
          media_range = Range.new('text', 'json')

          assert(
            media_range.send(method, 'text/json'),
            "Expected \"text/json\" to #{verb_phrase} #{media_range.inspect}."
          )
          ['text/plain', 'application/json'].each do |arg|
            assert(
              !media_range.send(method, arg),
              "Expected #{arg.inspect} not to #{verb_phrase} #{media_range.inspect}."
            )
          end
        end

        define_method(:"test_#{name}_on_wildcard_subtype") do
          media_range = Range.new('text', '*')

          %w[text/plain text/json].each do |arg|
            assert(
              media_range.send(method, arg),
              "Expected #{arg.inspect} #{verb_phrase} #{media_range.inspect}."
            )
          end
          ['application/json'].each do |arg|
            assert(
              !media_range.send(method, arg),
              "Expected #{arg.inspect} not to #{verb_phrase} #{media_range.inspect}."
            )
          end
        end

        define_method(:"test_#{name}_on_wildcard_type") do
          media_range = Range.new('*', 'json')

          %w[application/json text/json].each do |arg|
            assert(
              media_range.send(method, arg),
              "Expected #{arg.inspect} to #{verb_phrase} #{media_range.inspect}."
            )
          end
          ['text/plain'].each do |arg|
            assert(
              !media_range.send(method, arg),
              "Expected #{arg.inspect} not to #{verb_phrase} #{media_range.inspect}."
            )
          end
        end

        define_method(:"test_#{name}_on_wildcard_type_and_subtype") do
          media_range = Range.new('*', '*')

          ['text/plain', 'text/json', 'application/json'].each do |arg|
            assert(
              media_range.send(method, arg),
              "Expected #{arg.inspect} to #{verb_phrase} #{media_range.inspect}."
            )
          end
        end

        define_method(:"test_#{name}_on_nil") do
          media_range = Range.new('*', '*')
          assert_nil(media_range.send(method, nil))
        end
      end

      def test_priority
        assert_equal(1, Range.new('text', 'json').priority)
        assert_equal(2, Range.new('text', '*').priority)
        assert_equal(3, Range.new('*', 'json').priority)
        assert_equal(4, Range.new('*', '*').priority)
      end

      def test_inspect
        assert_equal(
          '#<Jsapi::Media::Range "text/*">',
          Range.new('text', '*').inspect
        )
      end

      def test_to_s
        assert_equal('text/*', Range.new('text', '*').to_s)
      end
    end
  end
end
