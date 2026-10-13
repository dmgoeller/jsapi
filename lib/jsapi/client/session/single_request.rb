# frozen_string_literal: true

module Jsapi
  module Client
    module Session
      class SingleRequest < Base
        # Sends +request+ and finishes the session.
        def send_request(request)
          super
        ensure
          finish
        end
      end
    end
  end
end
