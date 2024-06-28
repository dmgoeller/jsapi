# frozen_string_literal: true

module Jsapi
  module DSL
    # Used to specify details of a parameter.
    class Parameter < Schema
      include Examples

      ##
      # :method: deprecated
      # :args: arg
      # Specifies whether or not the parameter is deprecated.
      #
      #   deprecated true

      ##
      # :method: description
      # :args: arg
      # Specifies the description of the parameter.

      ##
      # :method: in
      # :args: location
      # Specifies the location of the parameter.
      #
      # See Meta::Parameter::Model#in for further information.

      ##
      # :method: ref
      # :args: name
      # Specifies the name of the reusable parameter to be referred.

      ##
      # :method: schema
      # :args: name
      # Specifies the name of the reusable schema to be referred.
    end
  end
end
