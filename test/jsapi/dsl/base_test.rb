# frozen_string_literal: true

module Jsapi
  module DSL
    class BaseTest < Minitest::Test
      # #initialize

      def test_initialize_raises_an_error_when_a_file_is_attempted_to_be_imported_again
        meta_model = dummy_model

        Pathname.stub_any_instance(:read, '') do
          error = assert_raises(Error) do
            Base.new(
              meta_model, Pathname.new('foo'),
              parent: Base.new(
                meta_model, Pathname.new('bar'),
                parent: Base.new(meta_model, Pathname.new('foo'))
              )
            )
          end
          assert_equal('Attempted "foo" to be imported again', error.message)
        end
      end

      def test_initialize_raises_an_error_when_ref_and_block_are_specified_together
        meta_model = dummy_model do
          attribute :foo, Meta::Model::Reference
        end
        error = assert_raises(Error) do
          Base.new(meta_model) do
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
        meta_model = dummy_model do
          attribute :foo, String
        end
        configuration = Minitest::Mock.new
        pathname = Minitest::Mock.new

        configuration.expect(:pathname, pathname, %w[foo.rb])
        pathname.expect(:read, "foo 'bar'")
        pathname.expect(:to_path, 'foo.rb')

        Jsapi.stub(:configuration, configuration) do
          Base.new(meta_model) do
            import('foo')
          end
        end
        assert_equal('bar', meta_model.foo)
      end

      def test_import_raises_an_error_when_file_name_is_blank
        error = assert_raises(ArgumentError) do
          Base.new(dummy_model) do
            import ''
          end
        end
        assert_equal("file name can't be blank", error.message)
      end

      # #import_relative

      def test_import_relative
        meta_model = dummy_model do
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

        Base.new(meta_model, foo_path) do
          import_relative('bar')
        end
        assert_equal('bar', meta_model.foo)
      end

      def test_import_relative_when_initialized_without_path_name
        meta_model = dummy_model do
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
          Base.new(meta_model) do
            import_relative('foo')
          end
        end
        assert_equal('bar', meta_model.foo)
      end

      def test_import_relative_raises_an_error_when_file_name_is_blank
        error = assert_raises(ArgumentError) do
          Base.new(dummy_model) do
            import_relative ''
          end
        end
        assert_equal("file name can't be blank", error.message)
      end

      # Keywords

      def test_keyword
        meta_model = dummy_model do
          attribute :foo, String
        end

        Base.new(meta_model) { foo 'bar' }
        assert_equal('bar', meta_model.foo)
      end

      def test_keyword_on_array_attribute
        meta_model = dummy_model do
          attribute :foos, [String]
        end

        Base.new(meta_model) { foo 'bar' }
        assert_equal(%w[bar], meta_model.foos)
      end

      def test_keyword_on_hash_attribute
        meta_model = dummy_model do
          attribute :foos, { String => String }
        end

        Base.new(meta_model) { foo 'foo', 'bar' }
        assert_equal('bar', meta_model.foo('foo'))
      end

      def test_keyword_with_block
        meta_model = dummy_model do
          attribute :foo, (
            Class.new(Meta::Model::Base) do
              attribute :bar, String
            end
          )
        end

        Base.new(meta_model) do
          foo { bar 'bar' }
        end
        assert_equal('bar', meta_model.foo.bar)
      end

      def test_keyword_with_block_on_array_attribute
        meta_model = dummy_model do
          attribute :foos, [
            Class.new(Meta::Model::Base) do
              attribute :bar, String
            end
          ]
        end

        Base.new(meta_model) do
          foo { bar 'bar' }
        end
        assert_equal(%w[bar], meta_model.foos.map(&:bar))
      end

      def test_keyword_with_block_on_hash_attribute
        meta_model = dummy_model do
          attribute :foos, {
            String => Class.new(Meta::Model::Base) do
              attribute :bar, String
            end
          }
        end

        Base.new(meta_model) do
          foo('foo') { bar 'bar' }
        end
        assert_equal('bar', meta_model.foo('foo').bar)
      end

      def test_raises_an_error_on_unsupported_keyword
        meta_model = dummy_model

        error = assert_raises(RuntimeError) do
          Base.new(meta_model) { foo 'bar' }
        end
        assert_equal('unsupported keyword: foo', error.message)
      end

      # #respond_to?

      def test_respond_to
        meta_model = dummy_model do
          attribute :foo
        end

        base = Base.new(meta_model)
        assert(base.respond_to?(:foo))
        assert_not(base.respond_to?(:bar))
      end

      private

      def dummy_model(&block)
        Class.new(Meta::Model::Base, &block).new
      end
    end
  end
end
