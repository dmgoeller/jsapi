# frozen_string_literal: true

module Jsapi
  module Controller
    # Used to jsonify a response.
    class Response
      class JsonifyError < RuntimeError # :nodoc:
        def message
          [@path&.delete_prefix('.') || 'response body', super].join(' ')
        end

        def prepend(origin)
          @path = "#{origin}#{@path}"
          self
        end
      end

      # Creates a new instance to jsonify +object+ according to +response+. References
      # are resolved to API components in +definitions+.
      #
      # The +:omit+ option specifies on which conditions properties are omitted.
      # Possible values are:
      #
      # - +:empty+ - All of the  properties whose value is empty are omitted.
      # - +:nil+ - All of the properties whose value is +nil+ are omitted.
      #
      # Raises an +ArgumentError+ when +:omit+ is other than +:empty+, +:nil+ or +nil+.
      def initialize(object, response, definitions, omit: nil)
        @object = object
        @response = response
        @definitions = definitions

        @omittable_check =
          case omit
          when nil
            nil
          when :nil
            ->(value, schema) { schema.omittable? && value.nil? }
          when :empty
            ->(value, schema) { schema.omittable? && value.try(:empty?) }
          else
            raise InvalidArgumentError.new('omit', omit, valid_values: %i[empty nil])
          end
      end

      def inspect # :nodoc:
        "#<#{self.class.name} #{@object.inspect}>"
      end

      # Returns the \JSON representation of the response as a string.
      def to_json(*)
        schema = @response.schema.resolve(@definitions)
        with_locale { jsonify(@object, schema) }.to_json
      end

      # Writes the response in \JSON sequence text format to +stream+.
      def write_json_seq_to(stream)
        schema = @response.schema.resolve(@definitions)
        with_locale do
          items, item_schema =
            if schema.array? && @object.respond_to?(:each)
              [@object, schema.items.resolve(@definitions)]
            else
              [[@object], schema]
            end

          items.each do |item|
            stream.write("\u001E") # Record separator (see RFC 7464)
            stream.write(jsonify(item, item_schema).to_json)
            stream.write("\n")
          end
        end
        nil
      end

      private

      def jsonify(object, schema)
        object = schema.default_value(@definitions, context: :response) if object.nil?

        if object.nil?
          raise JsonifyError, "can't be nil" unless schema.nullable?
        else
          case schema.type
          when 'array'
            jsonify_array(object, schema)
          when 'boolean'
            object
          when 'integer'
            schema.convert(object.to_i)
          when 'number'
            schema.convert(object.to_f)
          when 'object'
            jsonify_object(object, schema)
          when 'string'
            schema.convert(
              case schema.format
              when 'date'
                object.to_date
              when 'date-time'
                object.to_datetime
              when 'duration'
                object.iso8601
              else
                object.to_s
              end
            )
          else
            raise JsonifyError, "has an invalid type: #{schema.type.inspect}"
          end
        end
      end

      def jsonify_array(array, schema)
        item_schema = schema.items.resolve(@definitions)
        index = 0

        Array(array).map do |item|
          item = jsonify(item, item_schema)
          index += 1
          item
        rescue JsonifyError => e
          raise e.prepend("[#{index}]")
        end
      end

      def jsonify_object(object, schema)
        schema = schema.resolve_schema(object, @definitions, context: :response)
        properties = {}

        # Add properties
        schema.resolve_properties(@definitions, context: :response).each_value do |property|
          property_schema = property.schema.resolve(@definitions)
          property_value = property.reader.call(object)
          property_value = property_schema.default if property_value.nil?
          next if @omittable_check&.call(property_value, property_schema)

          properties[property.name] = jsonify(property_value, property_schema)
        rescue JsonifyError => e
          raise e.prepend(".#{property.name}")
        end
        # Add additional properties
        if (additional_properties = schema.additional_properties)
          additional_properties_schema = additional_properties.schema.resolve(@definitions)

          additional_properties.source.call(object)&.each do |key, value|
            next if properties.key?(key = key.to_s)

            properties[key] = jsonify(value, additional_properties_schema)
          rescue JsonifyError => e
            raise e.prepend(".#{key}")
          end
        end

        properties.presence
      end

      def with_locale(&block)
        if @response.locale
          I18n.with_locale(@response.locale, &block)
        else
          yield
        end
      end
    end
  end
end
