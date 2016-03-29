require_relative 'base'
require_relative '../trace'
require 'faraday'

module RequestTracer
  module Integration
    module FaradayHandler
      extend self
      def activate
        ::Faraday::Request.register_middleware(nil, tracing: FaradayTracing)
        builder = Faraday::RackBuilder.new
        builder.insert 0, FaradayTracing
        Faraday.default_connection_options.builder = builder
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
