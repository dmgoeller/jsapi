# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Model
    class NestableTest < Minitest::Test
      class Dummy
        include Nestable

        attr_reader :raw_additional_attributes, :raw_attributes

        def initialize(raw_additional_attributes: {}, raw_attributes: {})
          @raw_additional_attributes = raw_additional_attributes
          @raw_attributes = raw_attributes
        end
      end

      # Serialization

      def test_serializable_hash
        serializable_value = Struct.new(:value) do
          def serializable_value(*)
            value
          end
        end
        dummy = Dummy.new(
          raw_attributes: {
            'foo' => serializable_value.new('bar')
          },
          raw_additional_attributes: {
            'bar' => serializable_value.new('foo')
          }
        )
        assert_equal(
          { 'foo' => 'bar', 'bar' => 'foo' },
          dummy.serializable_hash
        )
        assert_equal(
          { 'foo' => 'bar' },
          dummy.serializable_hash(only: %w[foo])
        )
        assert_equal(
          { 'bar' => 'foo' },
          dummy.serializable_hash(except: %w[foo])
        )
        assert_equal(
          { foo: 'bar', bar: 'foo' },
          dummy.serializable_hash(symbolize_names: true)
        )
      end

      # Inspection

      def test_inspect
        assert_equal(
          "#<#{Dummy.name} additional_attributes: {}>",
          Dummy.new.inspect
        )
      end

      def test_inspect_on_attributes
        assert_equal(
          "#<#{Dummy.name} foo: \"bar\", additional_attributes: {}>",
          Dummy.new(raw_attributes: { 'foo' => 'bar' }).inspect
        )
      end

      def test_inspect_on_additional_attributes
        assert_equal(
          "#<#{Dummy.name} additional_attributes: {\"foo\"=>\"bar\"}>",
          Dummy.new(raw_additional_attributes: { 'foo' => 'bar' }).inspect
        )
      end
    end
  end
end
