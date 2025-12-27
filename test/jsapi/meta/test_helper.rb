# frozen_string_literal: true

module Jsapi
  module Meta
    module TestHelper
      OPENAPI_VERSIONS = OpenAPI.constants.filter_map do |c|
        OpenAPI.const_get(c) if c.to_s.match?(/V[1-9]+_[0-9]+/)
      end.sort.freeze

      def assert_json_equal(expected, actual)
        expected, actual = expected&.as_json, actual&.as_json

        assert(
          expected == actual,
          if expected.nil?
            <<~MESSAGE
              Expected JSON to be nil.

              Actual:
              #{::JSON.pretty_generate(actual)}
            MESSAGE
          else
            <<~MESSAGE
              Expected JSON to be:
              #{::JSON.pretty_generate(expected)}

              Actual:
              #{::JSON.pretty_generate(actual)}
            MESSAGE
          end
        )
      end

      def assert_openapi_equal(expected, object, version, *args, method: :to_openapi)
        expected = expected&.as_json
        actual = object.send(method, version, *args)&.as_json

        assert(
          expected == actual,
          if expected.nil?
            <<~MESSAGE
              Expected OpenAPI #{version} object to be nil.

              Actual:
              #{::JSON.pretty_generate(actual)}
            MESSAGE
          else
            <<~MESSAGE
              Expected OpenAPI #{version} object to be:
              #{::JSON.pretty_generate(expected)}

              Actual:
              #{::JSON.pretty_generate(actual)}
            MESSAGE
          end
        )
      end

      def each_openapi_version(from: nil, to: nil, &block)
        OPENAPI_VERSIONS
          .reject { |version| from&.>(version) || to&.<(version) }
          .each(&block)
      end
    end
  end
end
