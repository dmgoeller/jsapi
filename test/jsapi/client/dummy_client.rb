# frozen_string_literal: true

module Jsapi
  module Client
    class DummyClient < Base
      class ServerError < StandardError; end

      raises ServerError, on: '5xx'

      attr_reader :base_uri, :http_options

      api do
        path '/foos' do
          parameter 'request_id', type: 'string'
          response '5xx', schema: 'Error'

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

        server name: 'localhost', url: 'http://localhost:{port}/api' do
          variable 'port', default: '3000'
        end
      end
    end
  end
end
