# frozen_string_literal: true

module Jsapi
  module DSL
    class BaseTest < Minitest::Test
      # #initialize

      def test_initialize_raises_an_error_when_a_file_is_attempted_to_be_imported_again
        definition = dummy_definition

        Pathname.stub_any_instance(:read, '') do
          error = assert_raises(Error) do
            Base.new(
              definition, Pathname.new('foo'),
              parent: Base.new(
                definition, Pathname.new('bar'),
                parent: Base.new(definition, Pathname.new('foo'))
              )
            )
          end
          assert_equal('Attempted "foo" to be imported again', error.message)
        end
      end

      def test_initialize_raises_an_error_when_ref_and_block_are_specified_together
        definition = dummy_definition do
          attribute :foo, Definition::Model::Reference
        end
        error = assert_raises(Error) do
          Base.new(definition) do
            foo(ref: 'bar') {}
          end
        end
        assert_equal(
          "reference can't be specified together with a block (at foo)",
          error.message
        )
      end

      # #import

      def test_import
        definition = dummy_definition do
          attribute :foo, String
        end
        configuration = Minitest::Mock.new
        pathname = Minitest::Mock.new

        configuration.expect(:pathname, pathname, %w[foo.rb])
        pathname.expect(:read, "foo 'bar'")
        pathname.expect(:to_path, 'foo.rb')

        Jsapi.stub(:configuration, configuration) do
          Base.new(definition) do
            import('foo')
          end
        end
        assert_equal('bar', definition.foo)
      end

      def test_import_raises_an_error_when_file_name_is_blank
        error = assert_raises(ArgumentError) do
          Base.new(dummy_definition) do
            import ''
          end
        end
        assert_equal("file name can't be blank", error.message)
      end

      # #import_relative

      def test_import_relative
        definition = dummy_definition do
          attribute :foo, String
        end
        parent_path = Minitest::Mock.new
        foo_path = Minitest::Mock.new
        bar_path = Minitest::Mock.new

        foo_path.expect(:read, '')
        foo_path.expect(:to_path, 'foo.rb')
        foo_path.expect(:parent, parent_path)
        parent_path.expect(:+, bar_path, %w[bar.rb])
        foo_path.expect(:==, false, [bar_path])
        bar_path.expect(:read, "foo 'bar'")
        bar_path.expect(:to_path, 'bar.rb')

        Base.new(definition, foo_path) do
          import_relative('bar')
        end
        assert_equal('bar', definition.foo)
      end

      def test_import_relative_when_initialized_without_path_name
        definition = dummy_definition do
          attribute :foo, String
        end
        configuration = Minitest::Mock.new
        api_defs_path = Minitest::Mock.new
        foo_path = Minitest::Mock.new

        configuration.expect(:pathname, api_defs_path)
        api_defs_path.expect(:+, foo_path, %w[foo.rb])
        foo_path.expect(:read, "foo 'bar'")
        foo_path.expect(:to_path, 'foo.rb')

        Jsapi.stub(:configuration, configuration) do
          Base.new(definition) do
            import_relative('foo')
          end
        end
        assert_equal('bar', definition.foo)
      end

      def test_import_relative_raises_an_error_when_file_name_is_blank
        error = assert_raises(ArgumentError) do
          Base.new(dummy_definition) do
            import_relative ''
          end
        end
        assert_equal("file name can't be blank", error.message)
      end

      # Keywords

      def test_keyword
        definition = dummy_definition do
          attribute :foo, String
        end

        Base.new(definition) { foo 'bar' }
        assert_equal('bar', definition.foo)
      end

      def test_keyword_on_array_attribute
        definition = dummy_definition do
          attribute :foos, [String]
        end

        Base.new(definition) { foo 'bar' }
        assert_equal(%w[bar], definition.foos)
      end

      def test_keyword_on_hash_attribute
        definition = dummy_definition do
          attribute :foos, { String => String }
        end

        Base.new(definition) { foo 'foo', 'bar' }
        assert_equal('bar', definition.foo('foo'))
      end

      def test_keyword_with_block
        definition = dummy_definition do
          attribute :foo, (
            Class.new(Definition::Model::Base) do
              attribute :bar, String
            end
          )
        end

        Base.new(definition) do
          foo { bar 'bar' }
        end
        assert_equal('bar', definition.foo.bar)
      end

      def test_keyword_with_block_on_array_attribute
        definition = dummy_definition do
          attribute :foos, [
            Class.new(Definition::Model::Base) do
              attribute :bar, String
            end
          ]
        end

        Base.new(definition) do
          foo { bar 'bar' }
        end
        assert_equal(%w[bar], definition.foos.map(&:bar))
      end

      def test_keyword_with_block_on_hash_attribute
        definition = dummy_definition do
          attribute :foos, {
            String => Class.new(Definition::Model::Base) do
              attribute :bar, String
            end
          }
        end

        Base.new(definition) do
          foo('foo') { bar 'bar' }
        end
        assert_equal('bar', definition.foo('foo').bar)
      end

      def test_raises_an_error_on_unsupported_keyword
        definition = dummy_definition

        error = assert_raises(RuntimeError) do
          Base.new(definition) { foo 'bar' }
        end
        assert_equal('unsupported keyword: foo', error.message)
      end

      # #respond_to?

      def test_respond_to
        definition = dummy_definition do
          attribute :foo
        end

        base = Base.new(definition)
        assert(base.respond_to?(:foo))
        assert_not(base.respond_to?(:bar))
      end

      # #deprecation_warning

      def test_deprecation_warning
        captured_message = nil

        Warning.stub(:warn, ->(message, *) { captured_message = message }) do
          Base.new(dummy_definition) do
            deprecation_warning('Lorem ipsum')
          end
        end
        assert_match(
          %r{\[DEPRECATION WARNING\] Lorem ipsum\nDefined at: .+/base_test.rb:},
          captured_message
        )
      end

      private

      def dummy_definition(&block)
        Class.new(Definition::Model::Base, &block).new
      end
    end
  end
end
