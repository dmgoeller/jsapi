# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    class PathnameTest < Minitest::Test
      def test_from_pathname
        pathname = Pathname.new('/foo')
        assert(pathname.equal?(Pathname.from(pathname)))
      end

      def test_from_string
        pathname = Pathname.from('foo/bar')
        assert_equal(%w[foo bar], pathname.segments)
      end

      def test_from_string_with_leading_slash
        pathname = Pathname.from('/foo/bar')
        assert_equal(%w[foo bar], pathname.segments)
      end

      def test_pathname_from_slash
        pathname = Pathname.from('/')
        assert_equal([''], pathname.segments)
      end

      def test_pathname_from_empty_string
        pathname = Pathname.from('')
        assert_equal([''], pathname.segments)
      end

      def test_pathname_from_nil
        pathname = Pathname.from(nil)
        assert_equal([], pathname.segments)
      end

      def test_equality_operator
        pathname = Pathname.new('/foo')

        assert(pathname == Pathname.new('/foo'))
        assert(pathname == Pathname.new('foo'))
        assert(pathname != Pathname.new('bar'))
      end

      def test_plus_operator
        pathname = Pathname.new('/foo')

        assert_equal(pathname, pathname + nil)
        # rubocop:disable Style/StringConcatenation
        assert_equal(['foo', ''], (pathname + '').segments)
        assert_equal(['foo', ''], (pathname + '/').segments)
        assert_equal(['foo', '', ''], (pathname + '//').segments)
        assert_equal(%w[foo bar], (pathname + '/bar').segments)
        # rubocop:enable Style/StringConcatenation
        assert_equal(%w[foo bar], (pathname + Pathname.new('/bar')).segments)
      end

      def test_plus_operator_on_root
        root = Pathname.new

        assert_equal(root, root + nil)
        # rubocop:disable Style/StringConcatenation
        assert_equal([''], (root + '').segments)
        assert_equal([''], (root + '/').segments)
        assert_equal(['', ''], (root + '//').segments)
        assert_equal(['foo'], (root + '/foo').segments)
        # rubocop:enable Style/StringConcatenation
        assert_equal(['foo'], (root + Pathname.new('/foo')).segments)
      end

      def test_ancestors
        root = Pathname.new
        assert_equal([root], root.ancestors)

        foo = Pathname.new('/foo')
        assert_equal([foo, root], foo.ancestors)

        foo_bar = Pathname.new('/foo/bar')
        assert_equal([foo_bar, foo, root], foo_bar.ancestors)
      end

      def test_inspect
        assert_equal('#<Jsapi::Meta::Pathname "/foo">', Pathname.new('foo').inspect)
      end

      def test_to_s
        assert_equal('/', Pathname.new.to_s)
        assert_equal('//', Pathname.new('').to_s)
        assert_equal('/foo', Pathname.new('foo').to_s)
        assert_equal('/foo', Pathname.new('/foo').to_s)
        assert_equal('/foo/bar', Pathname.new('foo', 'bar').to_s)
      end
    end
  end
end
