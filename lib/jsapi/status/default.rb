# frozen_string_literal: true

module Jsapi
  module Status
    # The default status.
    DEFAULT = Class.new(Base) do
      def inspect
        '#<Jsapi::Status::DEFAULT>'
      end

      def match?(_)
        true
      end
    end.new('default', priority: 3)
  end
end
