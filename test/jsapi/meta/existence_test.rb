# frozen_string_literal: true

module Jsapi
  module Meta
    class ExistenceTest < Minitest::Test
      Dummy = Struct.new(:null, :empty, keyword_init: true) do
        def null?
          null
        end

        def empty?
          empty
        end
      end

      def test_allow_omitted
        assert_equal(Existence::ALLOW_OMITTED, Existence.from(:allow_omitted))
      end

      def test_allow_nil
        assert_equal(Existence::ALLOW_NIL, Existence.from(:allow_nil))
      end

      def test_allow_null
        assert_equal(Existence::ALLOW_NIL, Existence.from(:allow_null))
      end

      def test_allow_empty
        assert_equal(Existence::ALLOW_EMPTY, Existence.from(:allow_empty))
      end

      def test_present
        assert_equal(Existence::PRESENT, Existence.from(:present))
      end

      def test_from_true
        assert_equal(Existence::PRESENT, Existence.from(true))
      end

      def test_from_false
        assert_equal(Existence::ALLOW_OMITTED, Existence.from(false))
      end

      def test_from_existence
        assert_equal(Existence::PRESENT, Existence.from(Existence::PRESENT))
      end

      def test_invalid_existence
        error = assert_raises(ArgumentError) { Existence.from('foo') }
        assert_equal('invalid existence: foo', error.message)
      end

      def test_present_is_greater_than_allow_empty
        assert(Existence::PRESENT > Existence::ALLOW_EMPTY)
      end

      def test_allow_empty_is_greater_than_allow_nil
        assert(Existence::PRESENT > Existence::ALLOW_EMPTY)
      end

      def test_allow_nil_is_greater_than_allow_ommitted
        assert(Existence::PRESENT > Existence::ALLOW_EMPTY)
      end

      def test_reach
        dummy = Dummy.new(null: true)
        assert(Existence::ALLOW_NIL.reach?(dummy))
        assert_not(Existence::ALLOW_EMPTY.reach?(dummy))

        dummy = Dummy.new(empty: true)
        assert(Existence::ALLOW_EMPTY.reach?(dummy))
        assert_not(Existence::PRESENT.reach?(dummy))

        dummy = Dummy.new
        assert(Existence::PRESENT.reach?(dummy))
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::Meta::Existence level: 1>',
          Existence::ALLOW_OMITTED.inspect
        )
      end
    end
  end
end
