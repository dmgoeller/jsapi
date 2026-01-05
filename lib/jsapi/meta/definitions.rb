# frozen_string_literal: true

module Jsapi
  module Meta
    class Definitions < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: base_path
      # The base path of the API.
      #
      # Applies to \OpenAPI 2.0.
      attribute :base_path, Pathname

      ##
      # :attr: callbacks
      # The reusable callbacks. Maps strings to Callback objects or references.
      #
      # Applies to \OpenAPI 3.0 and higher.
      attribute :callbacks, { String => Callback }

      ##
      # :attr: defaults
      # The registered default values for different schema types. Maps schema
      # types to Defaults object.
      attribute :defaults, { String => Defaults }, keys: Schema::TYPES

      ##
      # :attr: examples
      # The reusable examples. Maps example names to Example objects or references.
      #
      # Applies to \OpenAPI 3.0 and higher.
      attribute :examples, { String => Example }

      ##
      # :attr: external_docs
      # The ExternalDocumentation object.
      attribute :external_docs, ExternalDocumentation

      ##
      # :attr: headers
      # The reusable headers. Maps header names to Header objects or references.
      #
      # Applies to \OpenAPI 3.0 and higher.
      attribute :headers, { String => Header }

      ##
      # :attr: host
      # The host serving the API.
      #
      # Applies to \OpenAPI 2.0.
      attribute :host, String

      ##
      # :attr: info
      # The Info object.
      attribute :info, Info

      ##
      # :attr: links
      # The reusable links. Maps link names to Link objects.
      #
      # Applies to \OpenAPI 3.0 and higher.
      attribute :links, { String => Link }

      ##
      # :attr: on_rescues
      # The methods or procs to be called whenever an exception is rescued.
      attribute :on_rescues, []

      ##
      # :attr: operations
      # The operations. Maps operation names to Operation objects.
      attribute :operations, { String => Operation }, accessors: %i[reader writer]

      ##
      # :attr: parameters
      # The reusable parameters. Maps parameter names to Parameter objects
      # or references.
      attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

      ##
      # :attr: paths
      # The paths. Maps instances of Pathname to Path objects.
      attribute :paths, { Pathname => Path }, accessors: %i[reader writer]

      ##
      # :attr: rescue_handlers
      # The registered rescue handlers.
      attribute :rescue_handlers, [RescueHandler]

      ##
      # :attr: request_bodies
      # The reusable request bodies. Maps request body names to RequestBody
      # objects or references.
      attribute :request_bodies, { String => RequestBody }

      ##
      # :attr: responses
      # The reusable responses. Maps response names to Response objects or
      # references.
      attribute :responses, { String => Response }

      ##
      # :attr: schemas
      # The reusable schemas. Maps schema names to Schema objects or references.
      attribute :schemas, { String => Schema }

      ##
      # :attr: schemes
      # The transfer protocols supported by the API. Can contain one or more of:
      #
      # - <code>"http"</code>
      # - <code>"https"</code>
      # - <code>"ws"</code>
      # - <code>"wss"</code>
      #
      # Applies to \OpenAPI 2.0.
      attribute :schemes, [String], values: %w[http https ws wss]

      ##
      # :attr: security_requirements
      # The top-level security requirements.
      attribute :security_requirements, [SecurityRequirement]

      alias add_security add_security_requirement

      ##
      # :attr: security_schemes
      # The security schemes.
      attribute :security_schemes, { String => SecurityScheme }

      ##
      # :attr: servers
      # The servers providing the API.
      #
      # Applies to \OpenAPI 3.0 and higher.
      attribute :servers, [Server]

      ##
      # :attr: tags
      # The tags.
      attribute :tags, [Tag]

      # The class to which this instance is assigned.
      attr_reader :owner

      # The +Definitions+ instance from which this instance inherits.
      attr_reader :parent

      def initialize(keywords = {})
        keywords = keywords.dup
        @owner = keywords.delete(:owner)
        @parent = keywords.delete(:parent)
        included = keywords.delete(:include)
        super(keywords)

        Array(included).each do |definitions|
          include(definitions)
        end
        @parent&.inherited(self)
      end

      def add_operation(name, parent_path = nil, keywords = {}) # :nodoc:
        try_modify_attribute!(:operations) do
          parent_path, keywords = nil, parent_path if parent_path.is_a?(Hash)

          name = name.nil? ? default_operation_name : name.to_s
          parent_path ||= default_operation_name unless keywords[:path].present?

          (@operations ||= {})[name] = Operation.new(name, parent_path, keywords)
        end
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        try_modify_attribute!(:parameters) do
          name = name.to_s

          (@parameters ||= {})[name] = Parameter.new(name, keywords)
        end
      end

      def add_path(name, keywords = {}) # :nodoc:
        try_modify_attribute!(:paths) do
          pathname = Pathname.from(name)

          (@paths ||= {})[pathname] = Path.new(pathname, self, keywords)
        end
      end

      # Returns an array containing itself and all of the +Definitions+ instances
      # inherited or included.
      def ancestors
        @ancestors ||= [self].tap do |ancestors|
          [@included_definitions, @parent].flatten.each do |definitions|
            ancestors.push(*definitions.ancestors) if definitions
          end
        end.uniq
      end

      ##
      # :method: common_description
      # :args: pathname
      # Returns the most accurate description for the specified path.

      ##
      # :method: common_model
      # :args: pathname
      # Returns the common model of all operations in the specified path.

      ##
      # :method: common_response_body
      # :args: pathname
      # Returns the common request body of all operations in the specified path.

      ##
      # :method: common_servers
      # :args: pathname
      # Returns the most accurate servers for the specified path.

      ##
      # :method: common_summary
      # :args: pathname
      # Returns the most accurate summary for the specified path.

      %i[description model request_body servers summary].each do |name|
        define_method(:"common_#{name}") do |arg|
          arg = Pathname.from(arg || '')

          cache_path_attribute(arg, name) do
            arg.ancestors.lazy.filter_map do |pathname|
              ancestors.lazy.filter_map do |definitions|
                definitions.path(pathname)&.public_send(name).presence
              end.first
            end.first
          end
        end
      end

      ##
      # :method: common_parameters
      # :args: pathname
      # Returns the parameters that apply to all operations in the
      # specified path.

      ##
      # :method: common_responses
      # :args: pathname
      # Returns the responses that can be produced by all operations in the
      # specified path.

      %i[parameters responses].each do |name|
        define_method(:"common_#{name}") do |arg|
          arg = Pathname.from(arg || '')

          cache_path_attribute(arg, name) do
            arg.ancestors.flat_map do |pathname|
              ancestors.filter_map do |definitions|
                definitions.path(pathname)&.send(name)
              end
            end.reduce({}, &:reverse_merge).presence
          end
        end
      end

      ##
      # :method: common_security_requirements
      # :args: pathname
      # Returns the security requirements that apply to all operations in
      # the specified path.

      ##
      # :method: common_tags
      # :args: pathname
      # Returns the tags that apply to all operations in the specified path.

      %i[security_requirements tags].each do |name|
        define_method(:"common_#{name}") do |arg|
          arg = Pathname.from(arg || '')

          cache_path_attribute(arg, name) do
            arg.ancestors.filter_map do |pathname|
              ancestors.filter_map do |definitions|
                definitions.path(pathname)&.send(name)
              end
            end.flatten.uniq.presence
          end
        end
      end

      # Returns the default value for +type+ within +context+.
      def default_value(type, context: nil)
        cached_attributes.dig(:defaults, type.to_s)&.value(context: context)
      end

      # The security requirements that apply by default to all operations.
      def default_security_requirements
        cached_attributes[:security_requirements]
      end

      # Returns the operation with the specified name.
      def find_operation(name = nil)
        name = name&.to_s

        cache_operation(name) do
          if name.present?
            # Select the operation with the given name
            cached_attributes.dig(:operations, name)
          elsif operations.one?
            # Select the one and only operation
            operations.values.first
          end
        end
      end

      ##
      # :method: find_parameter
      # Returns the reusable parameter with the specified name.

      ##
      # :method: find_request_body
      # Returns the reusable request body with the specified name.

      ##
      # :method: find_response
      # Returns the reusable response with the specified name.

      ##
      # :method: find_schema
      # Returns the reusable schema with the specified name.

      ##
      # :method: find_security_scheme
      # Returns the security scheme with the specified name.

      %i[parameters request_bodies responses schemas security_schemes].each do |attribute_name|
        define_method(:"find_#{attribute_name.to_s.singularize}") do |name|
          cached_attributes.dig(attribute_name, name&.to_s)
        end
      end

      # Includes +definitions+.
      def include(definitions)
        if circular_dependency?(definitions)
          raise ArgumentError,
                'detected circular dependency between ' \
                "#{owner.inspect} and " \
                "#{definitions.owner.inspect}"
        end

        (@included_definitions ||= []) << definitions
        definitions.included(self)
        invalidate_ancestors
        self
      end

      # Invalidates cached ancestors.
      def invalidate_ancestors
        @ancestors = nil
        @cache = nil
        each_descendant(&:invalidate_ancestors)
      end

      # Invalidates cached attributes.
      def invalidate_attributes
        @cache = nil
        each_descendant(&:invalidate_attributes)
      end

      # Invalidates the given path attribute.
      def invalidate_path_attribute(pathname, name)
        pathname = Pathname.from(pathname)
        name = name.to_sym

        cached_path_attributes.fetch(pathname, nil)&.delete(name)
        @cache[:operations] = nil

        each_descendant do |descendant|
          descendant.invalidate_path_attribute(pathname, name)
        end
      end

      # Returns a hash representing the \JSON \Schema document for +name+.
      def json_schema_document(name)
        find_schema(name)&.to_json_schema&.tap do |json_schema_document|
          if (schemas = cached_attributes[:schemas].except(name.to_s)).any?
            json_schema_document[:definitions] = schemas.transform_values(&:to_json_schema)
          end
        end&.as_json
      end

      # Returns the methods or procs to be called when rescuing an exception.
      def on_rescue_callbacks
        cached_attributes[:on_rescues]
      end

      # Returns a hash representing the \OpenAPI document for +version+.
      #
      # Raises an +ArgumentError+ if +version+ is not supported.
      def openapi_document(version = nil)
        version = OpenAPI::Version.from(version)
        operations = cached_attributes[:operations].values

        openapi_paths = operations.group_by(&:full_path).to_h do |key, value|
          [
            key,
            OpenAPI::PathItem.new(
              value,
              description: common_description(key),
              parameters: common_parameters(key),
              summary: common_summary(key),
              servers: common_servers(key)
            ).to_openapi(version, self)
          ]
        end.presence

        openapi_objects = (
          %i[external_docs info parameters responses schemas
             security_requirements security_schemes tags] +
          if version == OpenAPI::V2_0
            %i[base_path host schemes]
          else
            %i[callbacks examples headers links request_bodies servers]
          end
        ).index_with do |key|
          value = cached_attributes[key]
          if key == :responses
            value = value.reject do |_name, response|
              response.resolve(self).nodoc?
            end
          end
          object_to_openapi(value, version).presence
        end

        with_openapi_extensions(
          if version == OpenAPI::V2_0
            openapi_server = cached_attributes[:servers].first || default_server
            uri = URI(openapi_server.url) if openapi_server
            {
              # Order according to the OpenAPI specification 2.x
              swagger: '2.0',
              info: openapi_objects[:info],
              host: openapi_objects[:host] || uri&.hostname,
              basePath: openapi_objects[:base_path] || uri&.path,
              schemes: openapi_objects[:schemes] || Array(uri&.scheme).presence,
              consumes:
                Media::Range.reduce(
                  operations.filter_map do |operation|
                    operation.request_body&.resolve(self)&.default_media_range
                  end
                ).presence,
              produces:
                operations.flat_map do |operation|
                  operation.responses.values.filter_map do |response|
                    response = response.resolve(self)
                    response.default_media_type unless response.nodoc?
                  end
                end.uniq.sort.presence,
              paths: openapi_paths,
              definitions: openapi_objects[:schemas],
              parameters: openapi_objects[:parameters],
              responses: openapi_objects[:responses],
              securityDefinitions: openapi_objects[:security_schemes]
            }
          else
            {
              # Order according to the OpenAPI specification 3.x
              openapi: version,
              info: openapi_objects[:info],
              servers:
                openapi_objects[:servers] ||
                [default_server&.to_openapi(version)].compact.presence,
              paths: openapi_paths,
              components: {
                schemas: openapi_objects[:schemas],
                responses: openapi_objects[:responses],
                parameters: openapi_objects[:parameters],
                examples: openapi_objects[:examples],
                requestBodies: openapi_objects[:request_bodies],
                headers: openapi_objects[:headers],
                securitySchemes: openapi_objects[:security_schemes],
                links: openapi_objects[:links],
                callbacks: openapi_objects[:callbacks]
              }.compact.presence
            }
          end.merge(
            security: openapi_objects[:security_requirements],
            tags: openapi_objects[:tags],
            externalDocs: openapi_objects[:external_docs]
          ).compact
        ).as_json
      end

      # Returns the first RescueHandler capable to handle +exception+, or nil
      # if no one could be found.
      def rescue_handler_for(exception)
        cached_attributes[:rescue_handlers].find { |r| r.match?(exception) }
      end

      protected

      # The +Definitions+ instances that directly inherit from this instance.
      attr_reader :children

      # The +Definitions+ instances that directly include this instance.
      attr_reader :dependent_definitions

      # The +Definitions+ instances included.
      attr_reader :included_definitions

      def attribute_changed(*) # :nodoc:
        invalidate_attributes
        super
      end

      # Invoked whenever it is included in another +Definitions+ instance.
      def included(definitions)
        (@dependent_definitions ||= []) << definitions
      end

      # rubocop:disable Lint/MissingSuper

      # Invoked whenever it is inherited by another +Definitions+ instance.
      def inherited(definitions)
        (@children ||= []) << definitions
      end

      # rubocop:enable Lint/MissingSuper

      private

      def cache
        @cache ||= {}
      end

      def cached_attributes
        cache[:attributes] ||= ancestors.each_with_object({}) do |ancestor, attr|
          self.class.attribute_names.each do |key|
            case value = ancestor.send(key)
            when Array
              (attr[key] ||= []).push(*value)
            when Hash
              if (hash = attr[key])
                value.each { |k, v| hash[k] = v unless hash.key?(k) }
              else
                attr[key] = value.dup
              end
            else
              attr[key] ||= value
            end
          end
        end
      end

      def cached_operations
        cache[:operations] ||= {}
      end

      def cached_path_attributes
        cache[:path_attributes] ||=
          cached_attributes[:operations]
          .values
          .map(&:full_path)
          .flat_map(&:ancestors)
          .uniq
          .to_h { |pathname| [pathname, {}] }
      end

      def cache_operation(name)
        operation = cached_operations[name]
        return operation if operation

        operation = yield
        cached_operations[name] = Operation.wrap(operation, self) if operation
      end

      def cache_path_attribute(pathname, name)
        path_attributes = cached_path_attributes[pathname]
        return path_attributes[name] if path_attributes&.key?(name)

        value = yield
        return unless value || path_attributes

        path_attributes ||= cached_path_attributes[pathname] = {}
        path_attributes[name] = value
      end

      def circular_dependency?(other)
        return true if other == self
        return false unless other.included_definitions&.any?

        other.included_definitions.any? { |included| circular_dependency?(included) }
      end

      def default_operation_name
        @default_operation_name ||=
          if (name = @owner.try(:name))
            name.demodulize.delete_suffix('Controller').underscore
          end
      end

      def default_server
        @default_server ||=
          if (name = @owner.try(:name))
            Server.new(
              url: name.deconstantize.split('::')
                       .map(&:underscore)
                       .join('/').prepend('/')
            )
          end
      end

      def each_descendant(&block)
        [*@children, *dependent_definitions].each(&block)
        nil
      end

      def object_to_openapi(object, version)
        case object
        when Array
          object.map { |item| object_to_openapi(item, version) }
        when Hash
          object.transform_values { |value| object_to_openapi(value, version) }
        else
          object.respond_to?(:to_openapi) ? object.to_openapi(version, self) : object
        end
      end
    end
  end
end
