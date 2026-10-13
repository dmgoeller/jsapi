# frozen_string_literal: true

module Jsapi
  module Client
    class DummyClient < Base
      attr_reader :base_uri, :http_options

      api_definitions do
        path '/foos' do
          parameter 'request_id', type: 'string'

          operation 'create', method: 'post' do
            request_body schema: 'Foo'
            response 201, 'Foo'
          end

          path '{id}' do
            parameter 'id', in: 'path', type: 'integer'
            response 404, schema: 'Error'

            operation 'read' do
              response 200, 'Foo'
            end

            operation 'update', method: 'patch' do
              request_body schema: 'Foo'
              response 200, 'Foo'
            end
          end
        end

        response 'Foo' do
          content 'application/json', schema: 'Foo'
          content 'text/plain'
        end

        schema 'Foo' do
          property 'id', type: 'integer', existence: true, read_only: true
          property 'bar', type: 'string'
        end

        schema 'Error' do
          property 'message', type: 'string'
        end
      end

      def initialize(uri = nil, http: nil)
        super(uri || 'http://localhost:3000/api', http: http)
      end
    end
  end
end
