# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class ContactTest < Minitest::Test
      include OpenAPITestHelper

      def test_empty_openapi_contact_object
        assert_openapi_equal({}, Contact.new, nil)
      end

      def test_full_openapi_contact_object
        contact = Contact.new(
          name: 'Foo',
          url: 'https://foo.bar',
          email: 'foo@foo.bar',
          openapi_extensions: { 'foo' => 'bar' }
        )
        assert_openapi_equal(
          {
            name: 'Foo',
            url: 'https://foo.bar',
            email: 'foo@foo.bar',
            'x-foo': 'bar'
          },
          contact,
          nil
        )
      end
    end
  end
end
