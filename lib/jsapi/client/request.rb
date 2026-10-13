# frozen_string_literal: true

module Jsapi
  module Client
    class RequestError < StandardError; end

    class Request
      class Headers
        delegate :each, to: :@headers

        def initialize(headers = nil) # :nodoc:
          @headers = {}
          headers&.each { |name, value| self[name] = value }
        end

        # Returns the value for +name+.
        def [](name)
          @headers[name.to_s]
        end

        # Sets the value for +name+ to +value+.
        def []=(name, value)
          name = name.to_s
          raise ArgumentError, "name can't be blank" if name.blank?

          if value.nil?
            @headers.delete(name)
          else
            @headers[name] = value.to_s
          end
        end

        def http_basic_auth(username = nil, password = nil)
          auth_param = Base64.strict_encode64("#{username}:#{password}")
          @headers['Authorization'] = "Basic #{auth_param}"
        end

        def http_bearer(token)
          auth_param = Base64.strict_encode64(token.to_s)
          raise ArgumentError, "token can't be blank" if auth_param.blank?

          @headers['Authorization'] = "Bearer #{auth_param}"
        end

        def inspect # :nodoc:
          "#<#{
            [
              self.class.name,
              @headers.map do |name, value|
                "#{name}: #{value.inspect}"
              end.sort.join(', ')
            ].compact_blank.join(' ')
          }>"
        end
      end

      class Parameters # :nodoc:
        def initialize(params = nil)
          @params = {}
          params&.each { |name, value| self[name] = value }
        end

        def [](name)
          @params[name.to_s.underscore]
        end

        def []=(name, value)
          name = name.to_s
          raise ArgumentError, "name can't be blank" if name.blank?

          @params[name.underscore] = value
        end

        def inspect # :nodoc:
          "#<#{
            [
              self.class.name,
              @params.map do |name, value|
                "#{name}: #{value.inspect}"
              end.sort.join(', ')
            ].compact_blank.join(' ')
          }>"
        end
      end

      # The content type.
      attr_accessor :content_type

      # The body.
      attr_accessor :body

      # The Headers.
      attr_reader :headers

      ##
      # :method: [](name)
      # Returns the parameter value for +name+.

      ##
      # :method: []=(name, value)
      # Sets the parameter value for +name+ to +value+.

      delegate :[], :[]=, to: :@params

      def initialize(base_uri, operation, headers: nil, params: nil) # :nodoc:
        @base_uri = base_uri
        @operation = operation
        @headers = Headers.new(headers)
        @params = Parameters.new(params)
      end

      def http_request # :nodoc:
        create_http_request.tap do |http_request|
          headers.each do |key, value|
            http_request[key] = value
          end

          if (request_body_definition = @operation.request_body)
            media_type = Media::Type.from(content_type || 'application/json')

            http_request.content_type = media_type.to_s
            http_request.body =
              if media_type.json?
                request_body_definition
                  .content_for(media_type)
                  .schema
                  .jsonify(body, context: :request, omit: :empty)
                  .to_json
              else
                body.to_s
              end
          end
        end
      rescue StandardError => e
        raise RequestError, e.message
      end

      def inspect # :nodoc:
        "#<#{self.class.name} " \
        "base_uri: #{@base_uri}, " \
        "operation: #{@operation.name.inspect}, " \
        "headers: #{@headers.inspect}, " \
        "parameters: #{@params.inspect}>"
      end

      private

      def create_http_request
        http_method = @operation.http_method

        # Try to instantiate a subclass of Net::HTTPRequest
        http_request_class = "Net::HTTP::#{http_method.camelize}".safe_constantize
        return http_request_class.new(http_request_uri) if http_request_class

        # Fallback to Net::HTTPGenericRequest even it should not be used directly
        Net::HTTPGenericRequest.new(
          http_method,
          @operation.request_body.present?,
          @operation.responses.values.lazy.any?(&:content?),
          http_request_uri
        )
      end

      def http_request_uri
        path = File.join(@base_uri.path, @operation.full_path.to_s)

        # Substitute variables in RFC 6570 format
        path.gsub!(/\{\w+\}/) do |match|
          @params[match[1..-2]].tap do |value|
            # Raise an error as a URI must not contain curly brackets.
            raise "#{match.inspect} cannot be substituted" if value.nil?
          end
        end

        # Merge base URI and path
        @base_uri.merge(path).tap do |uri|
          if (query_params = @operation.query_parameters).any?
            uri.query = query_params.transform_values do |parameter|
              parameter.schema.jsonify(
                @params[parameter.name],
                context: :request,
                omit: :empty
              )
            rescue Meta::Schema::JsonifyError => e
              raise e.prepend(parameter.name)
            end.compact.to_query
          end
        end
      end
    end
  end
end
