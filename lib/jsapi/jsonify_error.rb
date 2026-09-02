# frozen_string_literal: true

module Jsapi
  # Raised when jsonifying an object fails.
  class JsonifyError < RuntimeError
    attr_reader :path # :nodoc:

    def message
      [@path&.delete_prefix('.'), super].compact.join(' ')
    end

    def prepend(origin) # :nodoc:
      @path = "#{origin}#{@path}"
      self
    end
  end
end
