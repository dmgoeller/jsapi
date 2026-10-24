# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      module Test
        module ClassMethods
          # Stubs all sessions created in the passed block.
          #
          # Spying a single request session:
          #
          #   Jsapi::Client::Session::SingleRequest.spy(200, '{}') do |spy|
          #     # Call operation
          #     assert_equal('...', spy.request.body)
          #   end
          #
          # Spying a session with multiple requests:
          #
          #   Jsapi::Client::Session::Base.spy do |spy|
          #     spy.response_with(200, '{}')
          #     # Call operation
          #     assert_equal('...', spy.request.body)
          #
          #     spy.response_with(400, '{}')
          #     # Call operation
          #     assert_equal('...', spy.request.body)
          #   end
          def spy(...)
            return unless block_given?

            spy = Test::Spy.new(...)

            klass = singleton_class
            klass.alias_method(:__new__, :new)
            klass.define_method(:new) { |*| spy }

            begin
              yield spy
            ensure
              klass.undef_method(:new)
              klass.alias_method(:new, :__new__)
              klass.undef_method(:__new__)
            end
          end
        end
      end
    end
  end
end
