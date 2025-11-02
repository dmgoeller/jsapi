# frozen_string_literal: true

module Jsapi
  # Holds the \Jsapi configuration.
  class Configuration
    # The path where the API definitions are located relative to +Rails.root+.
    # The default is <code>"jsapi/api_defs"</code>.
    attr_accessor :api_defs_path

    def initialize # :nodoc:
      @api_defs_path = 'jsapi/api_defs'
    end

    # Returns the absolute +Pathname+ for +args+ within +api_defs_path+.
    def pathname(*args)
      return unless (root = Rails.root)

      root.join(*[api_defs_path, args].flatten)
    end
  end

  class << self
    # The singleton \Jsapi configuration.
    def configuration
      @configuration ||= Configuration.new
    end
  end
end
