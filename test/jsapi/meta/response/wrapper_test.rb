# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Meta
    module Response
      class WrapperTest < Minitest::Test
        def test_locale
          definitions = Definitions.new(
            responses: {
              'base' => {},
              'en' => { ref: 'base', locale: :en }
            }
          )
          assert_equal(
            :es,
            Wrapper.new(
              Reference.new(ref: 'en', locale: :es),
              definitions
            ).locale
          )
          assert_equal(
            :en,
            Wrapper.new(
              Reference.new(ref: 'en'),
              definitions
            ).locale
          )
          assert_nil(
            Wrapper.new(
              Reference.new(ref: 'base'),
              definitions
            ).locale
          )
        end

        def test_media_type_and_content_for
          media_type, content = Wrapper.new(
            response = Response.new(
              contents: {
                'application/json' => {}
              }
            ),
            Definitions.new
          ).media_type_and_content_for('*/*')

          assert_equal(Media::Type.new('application', 'json'), media_type)

          assert_kind_of(Content::Wrapper, content)
          assert_equal(response.content('application/json'), content.__getobj__)
        end

        def test_media_type_and_content_for_on_no_contents
          assert_nil(
            Wrapper.new(
              Response.new,
              Definitions.new
            ).media_type_and_content_for('application/json')
          )
        end
      end
    end
  end
end
