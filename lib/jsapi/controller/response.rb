# frozen_string_literal: true

module Jsapi
  module Controller
    # Used to jsonify a response.
    class Response
      # Creates a new instance to jsonify +object+ according to +content_model+.
      #
      # The +:omit+ option specifies on which conditions properties are omitted.
      # Possible values are:
      #
      # - +:empty+ - All of the  properties whose value is empty are omitted.
      # - +:nil+ - All of the properties whose value is +nil+ are omitted.
      def initialize(object, content_model, locale: nil, omit: nil)
        @object = object
        @content_model = content_model
        @locale = locale
        @omit = omit
      end

      # Returns the \JSON representation of the response.
      def as_json(*)
        with_locale do
          @content_model.schema.jsonify(
            @object,
            context: :response,
            omit: @omit
          )
        end
      rescue JsonifyError => e
        e.prepend('response body') if e.path.blank?
        raise e
      end

      def inspect # :nodoc:
        "#<#{self.class.name} #{@object.inspect}>"
      end

      # Returns the \JSON representation of the response as a string.
      def to_json(*)
        as_json.to_json
      end

      # Writes the response in \JSON sequence text format to +stream+.
      def write_json_seq_to(stream)
        schema = @content_model.schema
        object = @object
        object = schema.default_value(context: :response) if object.nil?

        with_locale do
          items, item_schema =
            if schema.array? && object.respond_to?(:each)
              [object, schema.items]
            else
              [[object], schema]
            end

          items.each_with_index do |item, index|
            stream.write("\u001E") # Record separator (see RFC 7464)
            stream.write(
              item_schema.jsonify(
                item,
                context: :response,
                omit: @omit
              ).to_json
            )
            stream.write("\n")
          rescue JsonifyError => e
            raise e.prepend("[#{index}]")
          end
        end
        nil
      end

      private

      def with_locale(&block)
        if @locale
          I18n.with_locale(@locale, &block)
        else
          yield
        end
      end
    end
  end
end
