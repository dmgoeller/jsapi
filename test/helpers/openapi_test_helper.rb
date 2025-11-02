# frozen_string_literal: true

module OpenAPITestHelper
  OPENAPI_VERSIONS = Jsapi::Meta::OpenAPI.constants.filter_map do |c|
    Jsapi::Meta::OpenAPI.const_get(c) if c.to_s.match?(/V[1-9]+_[0-9]+/)
  end.sort.freeze

  def assert_openapi_equal(expected, object, version, *args, method: :to_openapi)
    actual = object.send(method, version, *args)

    assert(
      expected == actual,
      if expected.nil?
        <<~MESSAGE
          Expected OpenAPI #{version} object to be nil.

          Actual:
          #{JSON.pretty_generate(actual)}
        MESSAGE
      else
        <<~MESSAGE
          Expected OpenAPI #{version} object to be:
          #{JSON.pretty_generate(expected)}

          Actual:
          #{JSON.pretty_generate(actual)}
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
