# frozen_string_literal: true

module Jsapi
  module Meta
    # Specifies a path.
    class Path < Model::Base
      ##
      # :attr: description
      # The description that applies to all operations in this path.
      # Applies to \OpenAPI 3.0 and higher.
      attribute :description, String

      ##
      # :attr_reader: name
      # The relative path as a Pathname.
      attribute :name, Pathname, accessors: %i[reader]

      ##
      # :attr: parameters
      # The Parameter objects applicable for all operations in this path.
      attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

      ##
      # :attr_reader: owner
      attribute :owner, accessors: %i[reader]

      ##
      # :attr: summary
      # The summary that applies to all operations in this path.
      # Applies to \OpenAPI 3.0 and higher.
      attribute :summary, String

      ##
      # :attr: servers
      # The Server objects that applies to all operations in this path.
      # Applies to \OpenAPI 3.0 and higher.
      attribute :servers, [Server]

      # Creates a new path with the given name and owner.
      def initialize(name, owner, keywords = {})
        @name = Pathname.from(name)
        @owner = owner
        super(keywords)
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        name = name.to_s

        Parameter.new(name, keywords).tap do |parameter|
          (@parameters ||= {})[name] = parameter
          @owner.try(:invalidate_path_parameters, self.name)
        end
      end
    end
  end
end
