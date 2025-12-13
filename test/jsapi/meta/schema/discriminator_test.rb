# frozen_string_literal: true

require 'test_helper'

require_relative '../test_helper'

module Jsapi
  module Meta
    module Schema
      class DiscriminatorTest < Minitest::Test
        include TestHelper

        # Mapping

        def test_mapping_on_string_keys
          mappings = { 'foo' => 'Foo', 'bar' => 'Bar' }
          discriminator = Discriminator.new(mappings: mappings)
          assert_equal(mappings, discriminator.mappings)
        end

        def test_mapping_on_integer_keys
          mappings = { 1 => 'Foo', 2 => 'Bar' }
          discriminator = Discriminator.new(mappings: mappings)
          assert_equal(mappings, discriminator.mappings)
        end

        def test_mapping_on_boolean_keys
          mappings = { false => 'Foo', true => 'Bar' }
          discriminator = Discriminator.new(mappings: mappings)
          assert_equal(mappings, discriminator.mappings)
        end

        # OpenAPI objects

        def test_minimal_openapi_discriminator_object
          discriminator = Discriminator.new(property_name: 'type')

          each_openapi_version do |version|
            assert_openapi_equal(
              if version == OpenAPI::V2_0
                'type'
              else
                { propertyName: 'type' }
              end,
              discriminator,
              version
            )
          end
        end

        def test_full_openapi_discriminator_object
          discriminator = Discriminator.new(
            property_name: 'type',
            mappings: { false => 'Foo', true => 'Bar' },
            default_mapping: 'Default',
            openapi_extensions: { 'foo' => 'bar' }
          )
          each_openapi_version do |version|
            assert_openapi_equal(
              case version
              when OpenAPI::V2_0
                'type'
              when OpenAPI::V3_0
                {
                  propertyName: 'type',
                  mapping: { 'false' => 'Foo', 'true' => 'Bar' }
                }
              when OpenAPI::V3_1
                {
                  propertyName: 'type',
                  mapping: { 'false' => 'Foo', 'true' => 'Bar' },
                  'x-foo': 'bar'
                }
              else
                {
                  propertyName: 'type',
                  mapping: { 'false' => 'Foo', 'true' => 'Bar' },
                  defaultMapping: 'Default',
                  'x-foo': 'bar'
                }
              end,
              discriminator,
              version
            )
          end
        end
      end
    end
  end
end
