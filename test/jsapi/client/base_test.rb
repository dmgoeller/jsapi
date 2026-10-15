# frozen_string_literal: true

require 'test_helper'

require_relative 'dummy_client'

module Jsapi
  module Client
    class BaseTest < Minitest::Test

      # Base URI

      def test_base_uri
        uri = URI('https://foo.bar')
        assert_equal(uri, DummyClient.new(uri).base_uri)
      end

      def test_base_uri_from_string
        uri = 'https:/foo.bar'
        assert_equal(URI(uri), DummyClient.new(uri).base_uri)
      end

      def test_raises_an_error_if_base_uri_is_invalid
        assert_raises(ArgumentError) do
          DummyClient.new('httpa://foo.bar/ä')
        end
      end

      # HTTP options

      def test_http_options
        assert_equal(
          { read_timeout: 30 },
          DummyClient.new('http://foo.bar', http: { read_timeout: 30 }).http_options
        )
      end

      def test_use_ssl_on_https
        assert_equal(
          { use_ssl: true },
          DummyClient.new('https://foo.bar').http_options
        )
      end

      def test_raises_an_error_if_http_options_are_invalid
        error = assert_raises(ArgumentError) do
          DummyClient.new('httpa://foo.bar', http: 'foo')
        end
        assert_equal(':http must be a hash', error.message)
      end

      # Operation calls

      { 'call' => :call, 'call_bang' => :call! }.each do |name, symbol|
        define_method(:"test_#{name}") do
          client = DummyClient.new

          Session::SingleRequest.spy do |spy|
            spy.response_with(
              status_code = Status::Code.from(:ok),
              '{"id":1,"bar":"baz"}',
              content_type: 'application/json'
            )
            response = client.send(symbol, 'read', id: 1)

            assert_equal(status_code, response.status_code)
            assert_equal(1, response.content.id)
            assert_equal('baz', response.content.bar)

            assert_equal('/api/foos/1?', spy.request.path)
          end
        end

        define_method(:"test_#{name}_with_predefined_request_headers") do
          client = DummyClient.new
          client.request_headers['User-Agent'] = 'foo'

          Session::SingleRequest.spy do |spy|
            spy.response_with(:ok, '{"id":1,"bar":"baz"}', content_type: 'application/json')
            client.send(symbol, 'read', id: 1)

            assert_equal('foo', spy.request['User-Agent'])
          end
        end

        define_method(:"test_#{name}_with_body") do
          client = DummyClient.new

          Session::SingleRequest.spy do |spy|
            spy.response_with(
              status_code = Status::Code.from(:ok),
              '{"id":1,"bar":"baz"}',
              content_type: 'application/json'
            )
            response = client.send(symbol, 'update', { bar: 'baz' }, id: 1)

            assert_equal(status_code, response.status_code)
            assert_equal(1, response.content.id)
            assert_equal('baz', response.content.bar)

            assert_equal('{"bar":"baz"}', spy.request.body)
          end
        end

        define_method(:"test_#{name}_with_body_and_content_type") do
          client = DummyClient.new

          Session::SingleRequest.spy do |spy|
            spy.response_with(
              status_code = Status::Code.from(:ok),
              '{"id":1,"bar":"baz"}',
              content_type: 'application/json'
            )
            response = client.send(
              symbol,
              'update',
              { bar: 'baz' },
              'application/vnd.foo+json',
              id: 1
            )
            assert_equal(status_code, response.status_code)
            assert_equal(1, response.content.id)
            assert_equal('baz', response.content.bar)

            http_request = spy.request
            assert_equal('{"bar":"baz"}', http_request.body)
            assert_equal('application/vnd.foo+json', http_request.content_type)
          end
        end

        define_method(:"test_#{name}_with_block") do
          client = DummyClient.new

          Session::SingleRequest.spy do |spy|
            spy.response_with(
              status_code = Status::Code.from(:ok),
              '{"id":1,"bar":"baz"}',
              content_type: 'application/json'
            )
            response = client.send(symbol, 'update') do |request|
              request['id'] = 1
              request.headers['X-Request-ID'] = 'foo'
              request.content_type = 'application/json'
              request.body = { bar: 'baz' }
            end

            assert_equal(status_code, response.status_code)
            assert_equal(1, response.content.id)
            assert_equal('baz', response.content.bar)

            http_request = spy.request
            assert_equal('/api/foos/1?', http_request.path)
            assert_equal('foo', http_request['X-Request-ID'])
            assert_equal('{"bar":"baz"}', http_request.body)
            assert_equal('application/json', http_request.content_type)
          end
        end

        define_method(:"test_#{name}_in_session") do
          client = DummyClient.new

          Session::Base.spy do |spy|
            spy.response_with(
              :ok,
              '{"id":1,"bar":"baz"}',
              content_type: 'application/json'
            )
            client.start_session do
              client.send(symbol, 'read', id: 1)
            end
            assert_equal('/api/foos/1?', spy.request.path)
            assert_predicate(spy, :finished?)
          end
        end
      end

      def test_call_returns_nil_when_response_code_is_unexpected
        Session::SingleRequest.spy(:no_content) do
          assert_nil(DummyClient.new.call('read', id: 1))
        end
      end

      def test_call_bang_raises_an_error_when_response_code_is_unexpected
        error = assert_raises(UnexpectedResponseError) do
          Session::SingleRequest.spy(:no_content) do
            DummyClient.new.call!('read', id: 1)
          end
        end
        assert_equal('Unexpected status code 204 for operation "read"', error.message)
      end

      def test_call_bang_raises_an_error_when_response_body_is_invalid
        error = assert_raises(InvalidResponseBodyError) do
          Session::SingleRequest.spy(:ok, '{}', content_type: 'application/json') do
            DummyClient.new.call!('update', id: 1)
          end
        end
        assert_equal("'id' can't be blank.", error.message)
      end

      # Real HTTP requests

      if ENV['REAL_HTTP_REQUESTS'].present?
        def test_real_read_request
          client = DummyClient.new
          client.request_headers['x-foo'] = 'bar'

          response = client.call!('read', id: 1)

          assert_equal(Status::Code.from(:ok), response.status_code)
          assert_equal(1, response.content.id)
          assert_equal('baz', response.content.bar)
        end

        def test_real_update_request
          client = DummyClient.new
          client.request_headers['x-foo'] = 'bar'

          response = client.call!('update', { bar: 'baz' }, id: 1)

          assert_equal(Status::Code.from(:ok), response.status_code)
          assert_equal(1, response.content.id)
          assert_equal('baz', response.content.bar)
        end
      end

      # Sessions

      def test_start_session_closes_old_session
        client = DummyClient.new

        old_session = Session::Test::Spy.new
        new_session = Session::Test::Spy.new

        Session::Base.stub(:new, old_session) do
          client.start_session
        end
        assert_not(old_session.finished?)

        Session::Base.stub(:new, new_session) do
          client.start_session
        end
        assert_predicate(old_session, :finished?)
      end

      def test_start_session_closes_session_automatically
        session = Session::Test::Spy.new

        Session::Base.stub(:new, session) do
          DummyClient.new.start_session {}
        end
        assert_predicate(session, :finished?)
      end

      def test_start_session_returns_result_from_block
        assert_same(
          result = 'foo',
          Session::Base.stub(:new, Session::Test::Spy.new) do
            DummyClient.new.start_session { result }
          end
        )
      end

      def test_start_session_returns_nil_if_no_block_is_given
        assert_nil(
          Session::Base.stub(:new, Session::Test::Spy.new) do
            DummyClient.new.start_session
          end
        )
      end

      def test_finish_session_closes_current_session
        client = DummyClient.new
        session = Session::Test::Spy.new

        Session::Base.stub(:new, session) do
          client.start_session
        end
        assert_not(session.finished?)

        client.finish_session
        assert_predicate(session, :finished?)
      end

      def test_finish_session_returns_nil
        assert_nil(DummyClient.new.finish_session)
      end

      # Inspection

      def test_inspect
        assert_equal(
          '#<Jsapi::Client::Base base_uri: https://foo.bar, http: {:use_ssl=>true}>',
          Base.new('https://foo.bar').inspect
        )
      end
    end
  end
end
