# frozen_string_literal: true

module Jsapi
  module Client
    class Response
      class Body
        attr_reader :content, :errors

        def initialize(http_response_body, media_type, schema) # :nodoc:
          @http_response_body = http_response_body
          @errors = Model::Errors.new(self)
          @content =
            begin
              body = http_response_body
              body = ::JSON.parse(body) if media_type.json?

              if schema
                JSON.wrap(body, schema, context: :response).tap do |json|
                  json.validate(@errors)
                end.value
              else
                body
              end
            rescue ::JSON::ParserError => e
              @errors.add(:base, :invalid, message: e.message)
              nil
            end
        end

        def inspect # :nodoc:
          "#<#{self.class.name} #{@http_response_body.inspect}>"
        end

        def invalid?
          !valid?
        end

        def valid?
          errors.none?
        end
      end

      class Headers
        ##
        # :method: each
        delegate :each, to: :@headers

        def initialize(http_response, response_definition) # :nodoc:
          @headers = http_response.each_header.to_h do |name, value|
            if (header_definition = response_definition.header_for(name))
              schema = header_definition.schema
              value = value.split(',') if schema.array?
              value = JSON.wrap(value, schema, context: :response).value
            end
            [name.downcase, value]
          end
        end

        def [](name)
          @headers[name.downcase]
        end
      end

      ##
      # :attr_reader: body
      # The body of the response as Body.

      ##
      # :attr_reader: headers
      # The headers of the response as Headers.

      ##
      # :attr_reader: media_type
      # The media type of the response as Media::Type.
      attr_reader :media_type

      ##
      # :attr_reader: status_code
      # The status code of the response as Status::Code.
      attr_reader :status_code

      ##
      # :attr_reader: content
      # Same as +body.content+.
      delegate :content, to: :body

      # :nodoc:
      def initialize(http_response, response_definition)
        @http_response = http_response
        @response_definition = response_definition
        @status_code = Status::Code.from(@http_response.code)
        @media_type = Media::Type.from(@http_response.content_type)
      end

      def body
        @body ||= Body.new(
          @http_response.body,
          @media_type,
          @response_definition.content_for(@media_type).schema
        )
      end

      def headers
        @headers ||= Headers.new(@http_response, @response_definition)
      end

      def inspect # :nodoc:
        "#<#{self.class.name} #{@http_response.inspect}>"
      end
    end
  end
end
