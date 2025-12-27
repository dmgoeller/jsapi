# frozen_string_literal: true

module Jsapi
  module Meta
    module Schema
      class AdditionalProperties < Model::Base
        include Model::Wrappable

        delegate_missing_to :schema

        ##
        # :attr: schema
        # The Schema of additional properties.
        attribute :schema, accessors: %i[reader]

        ##
        # :attr: source
        # The Callable used to read additional properties. By default, additional properties
        # are read by calling the +additional_properties+ method or retrieving the value
        # assigned to the +:additional_properties+ key.
        attribute :source, Callable, default: Callable.from(:additional_properties)

        def initialize(keywords = {})
          keywords = keywords.dup
          super(keywords.extract!(:source))

          @schema = Schema.new(keywords)
        end

        class Wrapper < Model::Wrapper
          def schema
            @schema ||= Schema.wrap(super, definitions)
          end
        end
      end
    end
  end
end
