# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Media
    class TypeTest < Minitest::Test
      %i[from try_from].each do |method|
        define_method(:"test_#{method}_from_media_type_object") do
          media_type = Type.new('application', 'json')
          assert(Type.public_send(method, media_type).equal?(media_type))
        end

        define_method(:"test_#{method}_string") do
          %w[json json-seq problem+json vnd.foo vnd.foo+json].each do |subtype|
            media_type = Type.send(method, "application/#{subtype}")
            assert(
              media_type.type == 'application',
              "Expected type of #{media_type.inspect} to be \"application\"."
            )
            assert(
              media_type.subtype == subtype,
              "Expected subtype of #{media_type.inspect} to be #{subtype.inspect}."
            )
          end
        end
      end

      def test_from_raises_an_error_when_value_could_not_be_transformed
        [nil, '', 'application'].each do |value|
          error = assert_raises(ArgumentError) do
            Type.from(value)
          end
          assert_equal("invalid media type: #{value.inspect}", error.message)
        end
      end

      def test_try_from_returns_nil_when_value_could_not_be_transformed
        [nil, '', 'application'].each do |value|
          assert_nil(Type.try_from(value))
        end
      end

      def test_equality_operator
        media_type = Type.new('application', 'json')

        assert(
          media_type == other = Type.new('application', 'json'),
          "Expected #{other.inspect} to be equal to #{media_type.inspect}."
        )
        assert(
          media_type != other = Type.new('application', 'json-seq'),
          "Expected #{other.inspect} not to be equal to #{media_type.inspect}."
        )
        assert(
          media_type != other = Type.new('text', 'json'),
          "Expected #{other.inspect} not to be equal to #{media_type.inspect}."
        )
        assert(
          media_type != other = 'application/json',
          "Expected #{other.inspect} not to be equal to #{media_type.inspect}."
        )
      end

      def test_comparison_operator
        assert(
          media_range = Type.new('application', 'json') <
            other = Type.new('text', 'json'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert(
          media_range = Type.new('text', 'json') <
            other = Type.new('text', 'plain'),
          "Expected #{media_range.inspect} to be less than #{other.inspect}."
        )
        assert_nil(
          media_type = Type.new('application', 'json') <=>
            other = 'application/json',
          "Exptected #{other.inspect} to be not comparable to #{media_type.inspect}."
        )
      end

      def test_hash
        media_types = [
          Type.new('application', 'json'),
          Type.new('text', 'json'),
          Type.new('text', 'plain')
        ]
        hash = media_types.index_with(&:to_s)

        assert_equal(media_types, hash.keys)
      end

      def test_json_predicate
        [
          %w[application json],
          %w[application vnd.foo+json],
          %w[text json]
        ].each do |type, subtype|
          assert(
            (media_type = Type.new(type, subtype)).json?,
            "Expected #{media_type} to be a JSON type."
          )
        end
        [
          %w[application json-seq],
          %w[text plain]
        ].each do |type, subtype|
          assert(
            !(media_type = Type.new(type, subtype)).json?,
            "Expected #{media_type.inspect} not to be a JSON type."
          )
        end
      end

      def test_inspect
        assert_equal(
          '#<Jsapi::Media::Type "application/json">',
          Type.new('application', 'json').inspect
        )
      end

      def test_to_s
        assert_equal('application/json', Type.new('application', 'json').to_s)
      end
    end
  end
end
