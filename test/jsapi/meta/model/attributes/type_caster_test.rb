# frozen_string_literal: true

module Jsapi
  module Meta
    module Model
      module Attributes
        class TypeCasterTest < Minitest::Test
          def test_string_typecaster
            type_caster = TypeCaster.new(String)
            assert_equal('foo', type_caster.cast('foo'))
            assert_equal('foo', type_caster.cast(:foo))
            assert_equal('1', type_caster.cast(1))
            assert_nil(type_caster.cast(nil))
          end

          def test_symbol_typecaster
            type_caster = TypeCaster.new(Symbol)
            assert_equal(:foo, type_caster.cast('foo'))
            assert_equal(:foo, type_caster.cast(:foo))
            assert_equal(:'1', type_caster.cast(1))
            assert_nil(type_caster.cast(nil))
          end

          def test_enum_typecaster
            type_caster = TypeCaster.new(Symbol, values: %i[foo bar])
            assert_equal(:foo, type_caster.cast(:foo))

            error = assert_raises(ArgumentError) { type_caster.cast(nil) }
            assert_equal('value must be one of :foo or :bar, is nil', error.message)
          end

          def test_generic_typecaster
            type_caster = TypeCaster.new(
              foo_class = Class.new do
                def initialize(keywords = {})
                  @bar = keywords[:bar]
                end

                def bar
                  @bar || 'default'
                end
              end
            )
            foo = type_caster.cast({ bar: 'Bar' })
            assert_kind_of(foo_class, foo)
            assert_equal('Bar', foo.bar)

            foo = type_caster.cast(nil)
            assert_kind_of(foo_class, foo)
            assert_equal('default', foo.bar)

            assert foo.equal?(type_caster.cast(foo))
          end

          def test_generic_typecaster_on_from
            type_caster = TypeCaster.new(
              foo_class = Class.new do
                attr_accessor :bar

                def self.from(keywords = {})
                  new.tap { |foo| foo.bar = keywords[:bar] }
                end
              end
            )
            foo = type_caster.cast({ bar: 'Bar' })
            assert_kind_of(foo_class, foo)
            assert_equal('Bar', foo.bar)
          end

          def test_typeless_generic_typecaster
            type_caster = TypeCaster.new
            assert_equal('foo', type_caster.cast('foo'))
            assert_equal(1, type_caster.cast(1))
          end
        end
      end
    end
  end
end
