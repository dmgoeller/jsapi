# frozen_string_literal: true

module Jsapi
  module Meta
    class Definitions < Model::Base
      include OpenAPI::Extensions

      ##
      # :attr: base_path
      # The base path of the API. Applies to \OpenAPI 2.0.
      attribute :base_path, Pathname

      ##
      # :attr: callbacks
      # The reusable Callback objects. Applies to \OpenAPI 3.0 and higher.
      attribute :callbacks, { String => Callback }

      ##
      # :attr: defaults
      # The Defaults.
      attribute :defaults, { String => Defaults }, keys: Schema::TYPES

      ##
      # :attr: examples
      # The reusable Example objects. Applies to \OpenAPI 3.0 and higher.
      attribute :examples, { String => Example }

      ##
      # :attr: external_docs
      # The ExternalDocumentation object.
      attribute :external_docs, ExternalDocumentation

      ##
      # :attr: headers
      # The reusable Header objects. Applies to \OpenAPI 3.0 and higher.
      attribute :headers, { String => Header }

      ##
      # :attr: host
      # The host serving the API. Applies to \OpenAPI 2.0.
      attribute :host, String

      ##
      # :attr: info
      # The Info object.
      attribute :info, Info

      ##
      # :attr: links
      # The reusable Link objects. Applies to \OpenAPI 3.0 and higher.
      attribute :links, { String => Link }

      ##
      # :attr: on_rescues
      # The methods or procs to be called whenever an exception is rescued.
      attribute :on_rescues, []

      ##
      # :attr: operations
      # The Operation objects.
      attribute :operations, { String => Operation }, accessors: %i[reader writer]

      ##
      # :attr: parameters
      # The reusable Parameter objects.
      attribute :parameters, { String => Parameter }, accessors: %i[reader writer]

      ##
      # :attr: paths
      # The Path objects.
      attribute :paths, { Pathname => Path }, accessors: %i[reader writer]

      ##
      # :attr: rescue_handlers
      # The RescueHandler objects.
      attribute :rescue_handlers, [RescueHandler]

      ##
      # :attr: request_bodies
      # The reusable RequestBody objects.
      attribute :request_bodies, { String => RequestBody }

      ##
      # :attr: responses
      # The reusable Response objects.
      attribute :responses, { String => Response }

      ##
      # :attr: schemas
      # The reusable Schema objects.
      attribute :schemas, { String => Schema }

      ##
      # :attr: schemes
      # The array of transfer protocols supported by the API. Possible values are:
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
      # The array of SecurityRequirement objects.
      attribute :security_requirements, [SecurityRequirement]

      alias add_security add_security_requirement

      ##
      # :attr: security_schemes
      # The SecurityScheme objects.
      attribute :security_schemes, { String => SecurityScheme }

      ##
      # :attr: servers
      # The array of Server objects. Applies to \OpenAPI 3.0 and higher.
      attribute :servers, [Server]

      ##
      # :attr: tags
      # The array of Tag objects.
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
        parent_path, keywords = nil, parent_path if parent_path.is_a?(Hash)

        name = name.nil? ? default_operation_name : name.to_s
        parent_path ||= default_operation_name unless keywords[:path].present?

        (@operations ||= {})[name] = Operation.new(name, parent_path, keywords)
      end

      def add_parameter(name, keywords = {}) # :nodoc:
        name = name.to_s

        Parameter.new(name, keywords).tap do |parameter|
          (@parameters ||= {})[name] = parameter
          attribute_changed(:parameters)
        end
      end

      def add_path(name, keywords = {}) # :nodoc:
        pathname = Pathname.from(name)
        (@paths ||= {})[pathname] ||= Path.new(pathname, self, keywords)
      end

      # Returns an array containing itself and all of the +Definitions+ instances
      # inherited/included.
      def ancestors
        @ancestors ||= [self].tap do |ancestors|
          [@included_definitions, @parent].flatten.each do |definitions|
            ancestors.push(*definitions.ancestors) if definitions
          end
        end.uniq
      end

      # Returns the default value for +type+ within +context+.
      def default_value(type, context: nil)
        objects.dig(:defaults, type.to_s)&.value(context: context)
      end

      # Returns the operation with the specified name.
      def find_operation(name = nil)
        return objects.dig(:operations, name.to_s) if name.present?

        # Return the one and only operation
        operations.values.first if operations.one?
      end

      # Returns the reusable parameter with the specified name.
      def find_parameter(name)
        objects.dig(:parameters, name&.to_s)
      end

      # Returns the reusable request body with the specified name.
      def find_request_body(name)
        objects.dig(:request_bodies, name&.to_s)
      end

      # Returns the reusable response with the specified name.
      def find_response(name)
        objects.dig(:responses, name&.to_s)
      end

      # Returns the reusable schema with the specified name.
      def find_schema(name)
        objects.dig(:schemas, name&.to_s)
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

      # Resets the memoized parameters for the given path.
      def invalidate_path_parameters(pathname)
        pathname = Pathname.from(pathname)

        @path_parameters&.delete(pathname)
        each_descendant { |descendant| descendant.invalidate_path_parameters(pathname) }
      end

      # Returns a hash representing the \JSON \Schema document for +name+.
      def json_schema_document(name)
        find_schema(name)&.to_json_schema&.tap do |json_schema_document|
          if (schemas = objects[:schemas].except(name.to_s)).any?
            json_schema_document[:definitions] = schemas.transform_values(&:to_json_schema)
          end
        end
      end

      # Returns the methods or procs to be called when rescuing an exception.
      def on_rescue_callbacks
        objects[:on_rescues]
      end

      # Returns a hash representing the \OpenAPI document for +version+.
      #
      # Raises an +ArgumentError+ if +version+ is not supported.
      def openapi_document(version = nil)
        version = OpenAPI::Version.from(version)
        operations = objects[:operations].values

        openapi_paths = operations.group_by(&:full_path).to_h do |key, value|
          [
            key.to_s,
            OpenAPI::PathItem.new(
              value,
              description: path_description(key),
              parameters: path_parameters(key),
              summary: path_summary(key),
              servers: path_servers(key)
            ).to_openapi(version, self)
          ]
        end.presence

        openapi_objects =
          if version.major == 2
            %i[base_path external_docs info host parameters responses parameters schemas
               schemes security_requirements security_schemes tags]
          else
            %i[callbacks examples external_docs headers info links parameters request_bodies
               responses schemas security_requirements security_schemes servers tags]
          end.to_h { |key| [key, object_to_openapi(objects[key], version).presence] }

        with_openapi_extensions(
          if version.major == 2
            openapi_server = objects[:servers].first || default_server
            uri = URI(openapi_server.url) if openapi_server
            {
              # Order according to the OpenAPI specification 2.x
              swagger: '2.0',
              info: openapi_objects[:info],
              host: openapi_objects[:host] || uri&.hostname,
              basePath: openapi_objects[:base_path]&.to_s || uri&.path,
              schemes: openapi_objects[:schemes] || Array(uri&.scheme).presence,
              consumes: operations.filter_map do |operation|
                operation.consumes(self)
              end.uniq.sort.presence,
              produces: operations.flat_map do |operation|
                operation.produces(self)
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
              openapi:
                case version.minor
                when 0 then '3.0.3'
                when 1 then '3.1.1'
                when 2 then '3.2.0'
                end,
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
        )
      end

      ##
      # :method: path_description
      # :args: pathname
      # Returns the most accurate description for the given path.

      ##
      # :method: path_servers
      # :args: pathname
      # Returns the most accurate Server objects for the given path.

      ##
      # :method: path_summary
      # :args: pathname
      # Returns the most accurate summary for the given path.

      %i[description servers summary].each do |name|
        define_method(:"path_#{name}") do |arg|
          Pathname.from(arg).ancestors.each do |pathname|
            ancestors.each do |ancestor|
              value = ancestor.path(pathname)&.public_send(name)
              return value if value.present?
            end
          end
          nil
        end
      end

      # Returns a hash containing the Parameter objects that are applicable to all
      # operations in the given path.
      # :args: pathname
      def path_parameters(arg)
        arg = Pathname.from(arg || '')

        (@path_parameters ||= {})[arg] ||= arg.ancestors.flat_map do |pathname|
          ancestors.filter_map { |ancestor| ancestor.path(pathname)&.parameters }
        end.reduce(&:reverse_merge) || {}
      end

      # Returns the first RescueHandler to handle +exception+, or nil if no one could be found.
      def rescue_handler_for(exception)
        objects[:rescue_handlers].find { |r| r.match?(exception) }
      end

      protected

      # The +Definitions+ instances that directly inherit from this instance.
      attr_reader :children

      # The +Definitions+ instances that directly include this instance.
      attr_reader :dependent_definitions

      # The +Definitions+ instances included.
      attr_reader :included_definitions

      def attribute_changed(*) # :nodoc:
        invalidate_objects
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

      # Invalidates cached ancestors.
      def invalidate_ancestors
        @ancestors = nil
        @objects = nil
        @path_parameters = nil
        each_descendant(&:invalidate_ancestors)
      end

      # Invalidates cached objects.
      def invalidate_objects
        @objects = nil
        each_descendant(&:invalidate_objects)
      end

      private

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

      def objects
        @objects ||= ancestors.each_with_object({}) do |ancestor, objects|
          self.class.attribute_names.each do |key|
            case value = ancestor.send(key)
            when Array
              (objects[key] ||= []).push(*value)
            when Hash
              if (hash = objects[key])
                value.each { |k, v| hash[k] = v unless hash.key?(k) }
              else
                objects[key] = value.dup
              end
            else
              objects[key] ||= value
            end
          end
        end
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
