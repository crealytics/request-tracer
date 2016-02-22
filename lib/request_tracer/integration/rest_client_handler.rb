require_relative 'base'
require_relative '../trace'
module RequestTracer
  module Integration
    module RestClientHandler
      include Base
      extend self
      def activate
        require 'rest-client'
        RestClient.add_before_execution_proc do |req, params|
          Trace.record do |trace|
            extract_headers_from_fields(trace).each {|h, v| req[h] = v}
          end
        end
      end
    end
  end
end
