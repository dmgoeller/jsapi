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
      # :attr: model
      # The default model of all operations in this path.
      attribute :model, Class

      ##
      # :attr_reader: name
      # The relative path as a Pathname.
      attribute :name, Pathname, accessors: %i[reader]

      ##
      # :attr_reader: owner
      attribute :owner, accessors: %i[reader]

      ##
      # :attr: parameters
      # The parameters that are consumed by all operations in this path.
      attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

      ##
      # :attr: request_body
      # The default request body of all operations in this path.
      attribute :request_body, RequestBody

      ##
      # :attr: responses
      # The responses that can be produced by all operations in this path.
      attribute :responses, { String => Response }, default_key: 'default'

       ##
      # :attr: servers
      # The Server objects that apply to all operations in this path.
      # Applies to \OpenAPI 3.0 and higher.
      attribute :servers, [Server]

      ##
      # :attr: summary
      # The summary that applies to all operations in this path.
      # Applies to \OpenAPI 3.0 and higher.
      attribute :summary, String

      ##
      # :attr: tags
      # The tags that apply to all operations in this path.
      attribute :tags, [String]

      # Creates a new path with the given name and owner.
      def initialize(name, owner, keywords = {})
        @name = Pathname.from(name)
        @owner = owner
        super(keywords)
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        try_modify_attribute!(:parameters) do
          name = name.to_s
          (@parameters ||= {})[name] = Parameter.new(name, keywords)
        end
      end

      def inspect(*attributes) # :nodoc:
        super(*(attributes.presence || self.class.attribute_names).without(:owner))
      end

      protected

      def attribute_changed(name)
        @owner.try(:invalidate_path_attribute, self.name, name)
        super
      end
    end
  end
end
