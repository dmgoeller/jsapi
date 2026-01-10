# frozen_string_literal: true

module Jsapi
  module Controller
    class ResponseHashReaderTest < Minitest::Test
      def test_bracket_operator
        hash_reader = Response::HashReader.new(
          { foo: 'value of foo' }
        )
        assert_equal('value of foo', hash_reader[:foo])
        assert_nil(hash_reader['foo'])
      end

      def test_additional_properties
        hash_reader = Response::HashReader.new(
          hash = {
            foo: 'value of foo',
            bar: 'value of bar'
          }
        )
        assert_equal(
          hash,
          hash_reader.additional_properties,
          'Expected additional properties to contain all entries ' \
          'if no entry has been read yet'
        )
        # Read :foo
        hash_reader[:foo]

        assert_equal(
          { bar: 'value of bar' },
          hash_reader.additional_properties,
          'Expected additional properties to only contain entries ' \
          'that have not been read yet'
        )
        # Read :bar
        hash_reader[:bar]

        assert_equal(
          {},
          hash_reader.additional_properties,
          'Expected additional properties to be empty after all ' \
          'entries have been read'
        )
      end

      def test_additional_properties_as_entry_with_symbol_as_key
        hash_reader = Response::HashReader.new(
          {
            additional_properties: hash = {
              foo: 'value of foo',
              bar: 'value of bar'
            }
          }
        )
        assert_equal(hash, hash_reader.additional_properties)
      end

      def test_additional_properties_as_entry_with_string_as_key
        hash_reader = Response::HashReader.new(
          {
            'additional_properties' => hash = {
              'foo' => 'value of foo',
              'bar' => 'value of bar'
            }
          }
        )
        assert_equal(hash, hash_reader.additional_properties)
      end
    end
  end
end
