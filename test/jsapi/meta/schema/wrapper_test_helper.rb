# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      module WrapperTestHelper
        def assert_json_equal(expected, wrapper, value, **keywords)
          actual = wrapper.jsonify(value, **keywords)
          assert(
            actual.is_a?(expected.class) && actual == expected,
            "Expected #jsonify to return #{expected.inspect} (#{expected.class}) " \
            "for #{value.inspect}, is: #{actual.inspect} (#{actual.class})\n\n" \
            "Schema: #{wrapper.__getobj__.inspect}"
          )
        end

        def wrap_schema(definitions = nil, **keywords)
          class_name = self.class.name.delete_suffix('WrapperTest')

          "#{class_name}::Wrapper".constantize.new(
            class_name.constantize.new(**keywords),
            definitions || Definitions.new
          )
        end
      end
    end
  end
end
