require_relative 'base'

module RequestTracer
  module Integration
    class RackHandler
      include Base
      def initialize(app, config={})
        @app = app
        @tracer = config[:tracer] || Trace
      end
      def call(env)
        @tracer.record(extract_fields_from_headers(env)) do
          @app.call(env)
        end
      end
    end
  end
end
