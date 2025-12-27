# frozen_string_literal: true

require_relative 'attributes/frozen_error'
require_relative 'attributes/type_caster'
require_relative 'attributes/class_methods'

module Jsapi
  module Meta
    module Model
      module Attributes
        def self.included(base) # :nodoc:
          base.extend(ClassMethods)
        end

        # Returns true when attributes are frozen.
        def attributes_frozen?
          @attributes_frozen == true
        end

        # Freezes attributes.
        def freeze_attributes
          @attributes_frozen = true
        end

        protected

        # Invoked whenever an attribute has been changed.
        def attribute_changed(name); end

        private

        def try_modify_attribute!(name)
          raise FrozenError.new(self) if attributes_frozen?

          result = yield if block_given?
          attribute_changed(name)
          result
        end
      end
    end
  end
end
