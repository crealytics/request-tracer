require 'request_tracer/trace'
require 'request_tracer/integration/sidekiq_handler'
require 'sidekiq/testing'
Sidekiq.logger = Logger.new('/tmp/sidekiq.log')


describe RequestTracer::Integration::SidekiqHandler, :focus do
  include RequestTracer::Integration::Base

  class ResultChecker
    attr_reader :traces, :job_args
    def initialize
      @traces = []
      @job_args = []
    end
    def push_trace(trace)
      @traces.push(trace)
    end
    def push_job_args(args)
      @job_args.push(args)
    end
    def self.instance
      @checker ||= self.new
    end
    def self.clear
      @checker = nil
    end
  end

  class TraceableJob
    include Sidekiq::Worker
    def perform(*args)
      rc = ResultChecker.instance
      rc.push_trace(RequestTracer::Trace.latest.to_h)
      rc.push_job_args(args)
    end
  end

  class ThreadSpawningMiddleware
    def call(worker_class, job, queue, redis_pool, &blk)
      result = nil
      Thread.new { result = blk.call }.join
      result
    end
  end

  before(:all) do
    Sidekiq::Testing.inline!
    RequestTracer.integrate_with(:sidekiq)
    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.insert_after RequestTracer::Integration::SidekiqHandler::ClientMiddleware, ThreadSpawningMiddleware
      end
    end
  end

  let(:result_checker) { ResultChecker.instance }
  let(:trace) { RequestTracer::Trace.create }

  before do
    Sidekiq::Worker.clear_all
    RequestTracer::Trace.clear
    ResultChecker.clear
  end

  context "when asynchronously calling a job" do
    context "when there is an existing trace" do
      before { RequestTracer::Trace.push trace.to_h }
      it "passes the trace from the main process to the worker and records the worker" do
        TraceableJob.perform_async('foo')
        expect(result_checker.traces).to eq([trace.to_h])
      end
    end
    it "calls the job with the originally given parameters" do
      TraceableJob.perform_async(a_string: "bar", a_number: 12)
      expect(result_checker.job_args).to eq([[{"a_string" => "bar", "a_number" => 12}]])
    end
  end
end
