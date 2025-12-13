# frozen_string_literal: true

module Jsapi
  module DSL
    class ResponseTest < Minitest::Test
      # #content

      def test_content
        content = response content_type: 'foo/bar' do
          example 'foo bar'
        end.content('foo/bar')

        assert_predicate(content, :present?)
        assert_equal('foo bar', content.example('default').value)
      end

      # #example

      def test_example
        example = response do
          example 'foo'
        end.example('default')

        assert_predicate(example, :present?)
        assert_equal('foo', example.value)
      end

      # #header

      def test_header
        header = response do
          header 'X-Foo', description: 'Lorem ipsum'
        end.header('X-Foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      def test_header_with_block
        header = response do
          header 'X-Foo' do
            description 'Lorem ipsum'
          end
        end.header('X-Foo')

        assert_predicate(header, :present?)
        assert_equal('Lorem ipsum', header.description)
      end

      def test_header_reference
        header = response do
          header ref: 'x_foo'
        end.header('x_foo')

        assert_predicate(header, :present?)
        assert_equal('x_foo', header.ref)
      end

      def test_header_reference_by_name
        header = response do
          header 'X-Foo'
        end.header('X-Foo')

        assert_predicate(header, :present?)
        assert_equal('X-Foo', header.ref)
      end

      # #link

      def test_link
        link = response do
          link 'foo', description: 'Lorem ipsum'
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      def test_link_with_block
        link = response do
          link 'foo' do
            description 'Lorem ipsum'
          end
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('Lorem ipsum', link.description)
      end

      def test_link_reference
        link = response do
          link ref: 'foo'
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('foo', link.ref)
      end

      def test_link_reference_by_name
        link = response do
          link 'foo'
        end.link('foo')

        assert_predicate(link, :present?)
        assert_equal('foo', link.ref)
      end

      private

      def response(**keywords, &block)
        Meta::Response.new(keywords).tap do |response|
          Response.new(response, &block)
        end
      end
    end
  end
end
