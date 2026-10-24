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
          @headers[name.to_s.downcase]
        end

        # Sets the value for +name+ to +value+.
        #
        # Raises an +ArgumentError+ if name is blank.
        def []=(name, value)
          name = name.to_s.downcase
          raise ArgumentError, "name can't be blank" if name.blank?

          if value.nil?
            @headers.delete(name)
          else
            @headers[name] = value
          end
        end

        # Sets the username and password for HTTP Basic Authentication.
        def http_basic_auth(username = nil, password = nil)
          auth_param = Base64.strict_encode64("#{username}:#{password}")
          @headers['authorization'] = "Basic #{auth_param}"
        end

        def inspect # :nodoc:
          "#<#{
            [
              self.class.name,
              @headers.map { |name, value| "#{name}: #{value.inspect}" }.sort.join(', ')
            ].compact_blank.join(' ')
          }>"
        end
      end

      class Parameters
        def initialize(params = nil)
          @params = {}
          params&.each { |name, value| self[name] = value }
        end

        # Returns the value for +name+.
        def [](name)
          @params[name.to_s.underscore]
        end

        # Sets the value for +name+ to +value+.
        #
        # Raises an +ArgumentError+ if name is blank.
        def []=(name, value)
          name = name.to_s
          raise ArgumentError, "name can't be blank" if name.blank?

          @params[name.underscore] = value
        end

        def inspect # :nodoc:
          "#<#{
            [
              self.class.name,
              @params.map { |name, value| "#{name}: #{value.inspect}" }.sort.join(', ')
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
          http_headers.each { |name, value| http_request[name] = value }

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

        # Merge base URI and path and add query parameters
        @base_uri.merge(path).tap do |uri|
          if (querystring_param = @operation.querystring_parameter)
            querystring = @params[querystring_param.name]
            uri.query = querystring.to_s unless querystring.nil?
          elsif (query_params = @operation.query_parameters).any?
            uri.query = query_params.transform_values do |parameter|
              parameter.schema.jsonify(
                @params[parameter.name],
                context: :request,
                omit: :empty
              )
            rescue Definition::Schema::JsonifyError => e
              raise e.prepend(parameter.name)
            end.compact.to_query
          end
        end
      end

      def http_headers
        Headers.new.tap do |headers|
          @operation.header_parameters.each do |name, header_definition|
            value = @params[name] || @headers[name]
            next if value.nil?

            value = Array(value).join(',') if header_definition.schema.array?
            headers[name] = value
          end
          @headers.each do |name, value|
            headers[name] ||= value
          end
        end
      end
    end
  end
end
