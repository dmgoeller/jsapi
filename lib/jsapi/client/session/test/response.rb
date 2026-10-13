# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      module Test
        # Dummy HTTP response.
        class Response
          ##
          # :attr_reader: body
          # Mimics +body+ of Net::HTTPRespone.

          ##
          # :attr_reader: code
          # Mimics +code+ of Net::HTTPRespone.

          ##
          # :attr_reader: headers
          # The headers of the HTTP response as a hash.

          attr_reader :body, :code, :headers

          # Creates a dummy HTTP response. The default status code is <code>"200"</code>.
          def initialize(status_code = nil, body = nil, **headers)
            @code = Status::Code.from(status_code || :ok).to_s
            @body = body&.to_s

            @headers = headers.to_h do |key, value|
              [key.to_s.dasherize, value.to_s]
            end.freeze
          end

          # Mimics +content_type+ of Net::HTTPRespone.
          def content_type
            @headers['content-type']
          end

          # Mimics +each_header+ of Net::HTTPRespone.
          def each_header(&block)
            @headers.each(&block)
          end

          def inspect # :nodoc:
            "#<#{self.class.name} code: #{code}, " \
            "body: #{body.inspect}, headers: #{headers.inspect}>"
          end
        end
      end
    end
  end
end
