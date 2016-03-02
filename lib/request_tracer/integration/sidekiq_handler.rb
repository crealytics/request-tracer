require_relative 'base'
require_relative '../trace'
module RequestTracer
  module Integration
    module SidekiqHandler
      include Base
      extend self
      def activate
        require 'sidekiq'
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add ServerMiddleware
          end
        end
        Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add ClientMiddleware
          end
        end
      end

      class ServerMiddleware
        def call(worker, msg, queue)
          Trace.push(msg["trace"]) do |trace|
            yield
          end
        end
      end

      class ClientMiddleware
        def call(worker_class, job, queue, redis_pool)
          job['trace'] = Trace.latest.to_h
          yield
        end
      end
    end
  end
end
