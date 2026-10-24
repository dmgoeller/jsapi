# frozen_string_literal: true

require 'test_helper'

module Jsapi
  module Definition
    module Response
      class WrapperTest < Minitest::Test
        def test_locale
          api_definition = API.new(
            responses: {
              'base' => {},
              'en' => { ref: 'base', locale: :en }
            }
          )
          assert_equal(
            :es,
            Wrapper.new(
              Reference.new(ref: 'en', locale: :es),
              api_definition
            ).locale
          )
          assert_equal(
            :en,
            Wrapper.new(
              Reference.new(ref: 'en'),
              api_definition
            ).locale
          )
          assert_nil(
            Wrapper.new(
              Reference.new(ref: 'base'),
              api_definition
            ).locale
          )
        end

        def test_content?
          assert(
            Wrapper.new(
              Response.new(
                contents: {
                  'application/json' => {}
                }
              ),
              API.new
            ).content?
          )
          assert_not(
            Wrapper.new(
              Response.new,
              API.new
            ).content?
          )
        end

        def test_contents
          contents = Wrapper.new(
            response = Response.new(
              contents: {
                'application/json' => {}
              }
            ),
            API.new
          ).contents

          assert_equal(1, contents.count)

          media_type, content = contents.first
          assert_equal(Media::Type.new('application', 'json'), media_type)

          assert_kind_of(Content::Wrapper, content)
          assert_equal(response.contents.values.first, content.__getobj__)
        end

        def test_content_for
          content = Wrapper.new(
            response = Response.new(
              contents: {
                'application/json' => {}
              }
            ),
            API.new
          ).content_for('*/*')

          assert_kind_of(Content::Wrapper, content)
          assert_equal(response.content('application/json'), content.__getobj__)
        end

        def test_content_for_returns_nil_if_no_contents_exist
          assert_nil(
            Wrapper.new(
              Response.new,
              API.new
            ).content_for('application/json')
          )
        end

        def test_header_for
          response = Wrapper.new(
            Response.new(
              headers: {
                'Content-Length' => {
                  type: 'integer'
                }
              }
            ),
            API.new
          )
          header = response.header_for('Content-Length')
          assert_equal('integer', header.type)

          # Case-insensitive lookup
          assert_same(header, response.header_for('content-length'))
        end

        def test_media_type_and_content_for
          media_type, content = Wrapper.new(
            response = Response.new(
              contents: {
                'application/json' => {}
              }
            ),
            API.new
          ).media_type_and_content_for('*/*')

          assert_equal(Media::Type.new('application', 'json'), media_type)

          assert_kind_of(Content::Wrapper, content)
          assert_equal(response.content('application/json'), content.__getobj__)
        end

        def test_media_type_and_content_for_returns_nil_if_no_contents_exist
          assert_nil(
            Wrapper.new(
              Response.new,
              API.new
            ).media_type_and_content_for('application/json')
          )
        end
      end
    end
  end
end
