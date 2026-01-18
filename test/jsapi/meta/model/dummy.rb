# frozen_string_literal: true

module Jsapi
  module Meta
    module Dummy
      include Model::Wrappable

      class Base < Model::Base
        attribute :foo, String
      end

      class Reference < Model::Reference
        attribute :foo, String
      end

      class Wrapper < Model::Wrapper; end

      class Definitions
        def initialize(dummies:)
          @dummies = dummies
        end

        def find_dummy(name)
          @dummies[name]
        end
      end
    end
  end
end
