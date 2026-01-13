# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Response
      class ReferenceTest < Minitest::Test
        def test_hidden
          definitions = Definitions.new(
            responses: {
              'base' => {},
              'hidden' => { ref: 'base', nodoc: true }
            }
          )
          reference = Reference.new(ref: 'base')
          assert_not(reference.hidden?(definitions))

          reference = Reference.new(ref: 'base', nodoc: true)
          assert(reference.hidden?(definitions))

          reference = Reference.new(ref: 'hidden')
          assert(reference.hidden?(definitions))
        end
      end
    end
  end
end
