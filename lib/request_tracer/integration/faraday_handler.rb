require_relative 'base'
require_relative '../trace'
require 'faraday'

module RequestTracer
  module Integration
    module FaradayHandler
      extend self
      def activate
        ::Faraday::Middleware.register_middleware tracing: FaradayTracing
      end
    end
    class FaradayTracing < ::Faraday::Middleware
      include Base
      def call(env)
        Trace.record do |trace|
          env[:request_headers].merge!(extract_headers_from_fields(trace))
          @app.call(env)
        end
      end
    end
  end
end
