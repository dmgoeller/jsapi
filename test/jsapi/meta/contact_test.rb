# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ContactTest < Minitest::Test
      def test_empty_openapi_contact_object
        assert_equal({}, Contact.new.to_openapi)
      end

      def test_full_openapi_contact_object
        contact = Contact.new(
          name: 'Foo',
          url: 'https://foo.bar',
          email: 'foo@foo.bar',
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_equal(
          {
            name: 'Foo',
            url: 'https://foo.bar',
            email: 'foo@foo.bar',
            'x-foo': 'bar'
          },
          contact.to_openapi
        )
      end
    end
  end
end
