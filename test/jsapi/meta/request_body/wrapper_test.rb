# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module RequestBody
      class WrapperTest < Minitest::Test
        def test_content_for
          content = Wrapper.new(
            request_body = Base.new(
              contents: {
                'application/json' => {}
              }
            ),
            Definitions.new
          ).content_for('application/json')

          assert_kind_of(Content::Wrapper, content)
          assert_equal(request_body.default_content, content.__getobj__)
        end
      end
    end
  end
end
