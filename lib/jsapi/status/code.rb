# frozen_string_literal: true

module Jsapi
  module Status
    # Represents a status code.
    class Code < Base
      class << self
        # Transforms +value+ to an instance of this class.
        #
        # Raises an +ArgumentError+ if +value+ could not be transformed.
        def from(value)
          return value if value.nil? || value.is_a?(Code)

          code = status_code(value.to_sym) if value.respond_to?(:to_sym)
          code ||= value.to_i
          return new(code) if (100..599).cover?(code)

          raise ArgumentError, "invalid status code: #{value.inspect}"
        end

        def status_code(symbol)
          symbol_to_code[symbol]
        end

        private

        def symbol_to_code
          @symbol_to_code ||= {
            # Informational
            100 => :continue,
            101 => :switching_protocols,
            102 => :processing,
            103 => :early_hints,

            # Success
            200 => :ok,
            201 => :created,
            202 => :accepted,
            203 => :non_authoritative_information,
            204 => :no_content,
            205 => :reset_content,
            206 => :partial_content,
            207 => :multi_status,
            208 => :already_reported,
            226 => :im_used,

            # Redirection
            300 => :multiple_choices,
            301 => :moved_permanently,
            302 => :found,
            303 => :see_other,
            304 => :not_modified,
            307 => :temporary_redirect,
            308 => :permanent_redirect,

            # Client error
            400 => :bad_request,
            401 => :unauthorized,
            402 => :payment_required,
            403 => :forbidden,
            404 => :not_found,
            405 => :method_not_allowed,
            406 => :not_acceptable,
            407 => :proxy_authentication_required,
            408 => :request_timeout,
            409 => :conflict,
            410 => :gone,
            411 => :length_required,
            412 => :precondition_failed,
            413 => :content_too_large,
            414 => :uri_too_long,
            415 => :unsupported_media_type,
            416 => :range_not_satisfiable,
            417 => :expectation_failed,
            421 => :misdirected_request,
            422 => :unprocessable_content,
            423 => :locked,
            424 => :failed_dependency,
            425 => :too_early,
            426 => :upgrade_required,
            428 => :precondition_required,
            429 => :too_many_requests,
            431 => :request_header_fields_too_large,
            451 => :unavailable_for_legal_reasons,

            # Server error
            500 => :internal_server_error,
            501 => :not_implemented,
            502 => :bad_gateway,
            503 => :service_unavailable,
            504 => :gateway_timeout,
            505 => :http_version_not_supported,
            506 => :variant_also_negotiates,
            507 => :insufficient_storage,
            508 => :loop_detected,
            511 => :network_authentication_required
          }.invert
        end
      end

      delegate :to_i, to: :value

      def initialize(value) # :nodoc:
        super(value, priority: 1)
      end

      # Returns true if and only if +status_code+ is equal to itself.
      def match?(status_code)
        status_code == self
      end
    end
  end
end
