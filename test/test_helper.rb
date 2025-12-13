# frozen_string_literal: true

require 'minitest'

# SimpleCov
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  enable_coverage :branch
end

# Copied form SimpleCov's Minitest plug-in:
SimpleCov.external_at_exit = true
Minitest.after_run do
  SimpleCov.at_exit_behavior
end

# Active Support
require 'active_support'
require 'active_support/core_ext/module'
require 'active_support/core_ext/object'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/array'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/hash_with_indifferent_access'
require 'active_support/testing/assertions'

# Locales
ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.expand_path('config/locale/de.yml', __dir__)
  I18n.load_path << File.expand_path('config/locale/en.yml', __dir__)
end

# Dummies
require 'dummies/action_controller'
require 'dummies/action_dispatch'
require 'dummies/active_model'
require 'dummies/rails'

# This gem
require 'jsapi'

# Pry
require 'pry'

# Extend Minitest
module Minitest
  class Test
    include ActiveSupport::Testing::Assertions
  end
end

# Start Minitest
require 'minitest/stub_any_instance'
require 'minitest/autorun'
