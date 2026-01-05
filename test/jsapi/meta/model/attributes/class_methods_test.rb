# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      module Attributes
        class ClassMethodsTest < Minitest::Test
          def test_attribute_names
            foo_class = model_class do
              attribute :foo
            end
            assert_equal(%i[foo], foo_class.attribute_names)

            bar_class = Class.new(foo_class) do
              attribute :bar
            end
            assert_equal(%i[foo bar], bar_class.attribute_names)
          end

          def test_responds_to_accessors
            assert_responds(
              model do
                attribute :foo, Object
              end,
              to: %i[foo foo=]
            )
            assert_responds(
              model do
                attribute :foo, Object, accessors: %i[reader]
              end,
              to: :foo,
              not_to: :foo=
            )
            assert_responds(
              model do
                attribute :foo, Object, accessors: %i[writer]
              end,
              to: :foo=,
              not_to: :foo
            )
          end

          def test_attribute_reader_and_writer
            model = model do
              attribute :foo, Object, values: %w[foo bar]
            end

            result = model.send(:foo=, 'foo')
            assert_equal('foo', result)
            assert(result.equal?(model.foo))

            # Errors
            error = assert_raises(InvalidArgumentError) do
              model.foo = 'baz'
            end
            assert_equal('foo must be one of "foo" or "bar", is "baz"', error.message)
          end

          def test_default_value
            model = model do
              attribute :foo, Object, default: 'bar'
            end
            assert_equal('bar', model.foo)

            model = model do
              attribute :foo, Object, default: :nil
            end
            assert_nil(model.foo)
          end

          # Boolean attributes

          def test_responds_to_accessors_on_boolean
            assert_responds(
              model do
                attribute :foo, values: [true, false]
              end,
              to: %i[foo foo? foo=]
            )
            assert_responds(
              model do
                attribute :foo, values: [true, false], accessors: %i[reader]
              end,
              to: %i[foo foo?],
              not_to: :foo=
            )
            assert_responds(
              model do
                attribute :foo, values: [true, false], accessors: %i[writer]
              end,
              to: :foo=,
              not_to: %i[foo foo?]
            )
          end

          def test_predicate_method_on_boolean
            model = model do
              attribute :foo, values: [true, false]
            end

            model.foo = true
            assert(model.foo?)

            model.foo = false
            assert(!model.foo?)
          end

          def test_predicate_method_on_true_by_default
            model = model do
              attribute :foo, values: [true, false], default: true
            end
            assert(model.foo?)
          end

          # Array attributes

          def test_responds_to_accessors_on_array
            assert_responds(
              model do
                attribute :foos, []
              end,
              to: %i[foos foos= add_foo]
            )
            assert_responds(
              model do
                attribute :foos, [], accessors: %i[reader writer]
              end,
              to: %i[foos foos=],
              not_to: :add_foo
            )
            assert_responds(
              model do
                attribute :foos, [], accessors: %i[add reader]
              end,
              to: %i[foos add_foo],
              not_to: :foos=
            )
            assert_responds(
              model do
                attribute :foos, [], accessors: %i[add writer]
              end,
              to: %i[foos= add_foo],
              not_to: :foos
            )
          end

          def test_attribute_reader_and_writer_on_array
            model = model do
              attribute :foos, [], values: %w[foo bar]
            end
            assert_equal([], model.foos)

            result = model.send(:foos=, %w[foo bar])
            assert_equal(%w[foo bar], result)
            assert(result.equal?(model.foos))

            # Errors
            error = assert_raises(InvalidArgumentError) do
              model.foos = %w[baz]
            end
            assert_equal('foo must be one of "foo" or "bar", is "baz"', error.message)
          end

          def test_add_method_on_array
            model = model do
              attribute :foos, [], values: %w[foo]
            end
            result = model.add_foo('foo')
            assert_equal('foo', result)
            assert_equal(%w[foo], model.foos)

            # Errors
            error = assert_raises(InvalidArgumentError) do
              model.add_foo('bar')
            end
            assert_equal('foo must be "foo", is "bar"', error.message)
          end

          def test_default_value_on_array
            default_value = %w[foo bar]

            model = model do
              attribute :foos, [], default: default_value
            end
            assert_equal(default_value, model.foos)
          end

          def test_read_only_on_array
            model = model do
              attribute :foos, [String], accessors: %i[reader]
            end
            assert(!model.respond_to?(:foos=))
            assert(!model.respond_to?(:add_foo))
          end

          # Hash attributes

          def test_responds_to_accessors_on_hash
            assert_responds(
              model do
                attribute :foos, {}
              end,
              to: %i[foo foos foos= add_foo]
            )
            assert_responds(
              model do
                attribute :foos, {}, accessors: %i[reader writer]
              end,
              to: %i[foo foos foos=],
              not_to: :add_foo
            )
            assert_responds(
              model do
                attribute :foos, {}, accessors: %i[add reader]
              end,
              to: %i[foo foos add_foo],
              not_to: :foos=
            )
            assert_responds(
              model do
                attribute :foos, {}, accessors: %i[add writer]
              end,
              to: %i[foos= add_foo],
              not_to: %i[foo foos]
            )
          end

          def test_attribute_reader_and_writer_on_hash
            model = model do
              attribute :foos, {}, keys: %w[foo], values: %w[bar]
            end
            assert_equal({}, model.foos)

            result = model.send(:foos=, { 'foo' => 'bar' })
            assert_equal({ 'foo' => 'bar' }, result)
            assert(result.equal?(model.foos))

            # Errors
            error = assert_raises(ArgumentError) do
              model.foos = { '' => 'bar' }
            end
            assert_equal("key can't be blank", error.message)

            error = assert_raises(InvalidArgumentError) do
              model.foos = { 'bar' => 'bar' }
            end
            assert_equal('key must be "foo", is "bar"', error.message)

            error = assert_raises(InvalidArgumentError) do
              model.foos = { 'foo' => 'foo' }
            end
            assert_equal('value must be "bar", is "foo"', error.message)
          end

          def test_add_method_on_hash
            model = model do
              attribute :foos, {}, keys: %w[foo], values: %w[bar]
            end
            result = model.add_foo('foo', 'bar')
            assert_equal('bar', result)
            assert_equal({ 'foo' => 'bar' }, model.foos)

            # Errors
            error = assert_raises(ArgumentError) do
              model.add_foo('', 'bar')
            end
            assert_equal("key can't be blank", error.message)

            error = assert_raises(InvalidArgumentError) do
              model.add_foo 'bar', 'bar'
            end
            assert_equal('key must be "foo", is "bar"', error.message)

            error = assert_raises(InvalidArgumentError) do
              model.add_foo 'foo', 'foo'
            end
            assert_equal('value must be "bar", is "foo"', error.message)
          end

          def test_add_method_on_default_key
            model = model do
              attribute :foos, {}, default_key: 'bar'
            end
            model.add_foo('foo')
            assert_equal({ 'bar' => 'foo' }, model.foos)
          end

          def test_lockup_method_on_hash
            model = model do
              attribute :foos, {}
            end
            model.add_foo('foo', 'bar')
            assert_equal('bar', model.foo('foo'))

            assert_nil(model.foo(nil))
          end

          def test_default_value_on_hash
            default_value = { 'foo' => 'bar' }

            model = model do
              attribute :foos, {}, default: default_value
            end
            assert_equal(default_value, model.foos)
          end

          def test_read_only_on_hash
            model = model do
              attribute :foos, {}, accessors: %i[reader]
            end
            assert(!model.respond_to?(:foo=))
            assert(!model.respond_to?(:add_foo))
          end

          private

          def assert_responds(model, to: [], not_to: [])
            Array(to).each do |method|
              assert(
                model.respond_to?(method),
                "Expected model to respond to #{name}."
              )
            end
            Array(not_to).each do |method|
              assert(
                !model.respond_to?(method),
                "Expected model not to respond to #{name}."
              )
            end
          end

          def model(&block)
            model_class(&block).new
          end

          def model_class(&block)
            Class.new.tap do |klass|
              klass.include(Attributes)
              klass.class_eval(&block) if block
            end
          end
        end
      end
    end
  end
end
