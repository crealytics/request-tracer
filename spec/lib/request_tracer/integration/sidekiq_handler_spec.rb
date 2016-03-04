require 'request_tracer/trace'
require 'request_tracer/integration/sidekiq_handler'
require 'sidekiq/testing'
Sidekiq.logger = Logger.new('/tmp/sidekiq.log')


describe RequestTracer::Integration::SidekiqHandler do
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
    def call(worker_instance, msg, queue, &blk)
      result = nil
      Thread.new { result = blk.call }.join
      result
    end
  end

  before(:all) do
    Sidekiq::Testing.inline!
  end

  let(:result_checker) { ResultChecker.instance }
  let(:trace) { RequestTracer::Trace.create }

  before do
    Sidekiq::Worker.clear_all
    RequestTracer::Trace.clear
    ResultChecker.clear
  end

  after do
    Sidekiq::Testing.server_middleware {|chn| chn.clear }
    Sidekiq.configure_client {|cfg|  cfg.client_middleware {|chn| chn.clear } }
  end

  context "when asynchronously calling a job with correctly setup middleware" do
    before do
      RequestTracer.integrate_with(:sidekiq)
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ThreadSpawningMiddleware
        chain.add RequestTracer::Integration::SidekiqHandler::ServerMiddleware
      end
    end
    context "when there is an existing trace" do
      let(:subtrace) { trace.next_id }
      before do
        RequestTracer::Trace.push trace.to_h
        allow(RequestTracer::Trace).to receive(:record).and_yield(subtrace)
      end
      it "passes a sub-trace from the main process to the worker and pushes this on the trace stack in the worker" do
        TraceableJob.perform_async('foo')
        expect(result_checker.traces).to eq([subtrace.to_h])
      end
    end
    it "calls the job with the originally given parameters" do
      TraceableJob.perform_async(a_string: "bar", a_number: 12)
      expect(result_checker.job_args).to eq([[{"a_string" => "bar", "a_number" => 12}]])
    end
  end
  context "when asynchronously calling a job with missing server middleware" do
    before do
      RequestTracer.integrate_with(:sidekiq)
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ThreadSpawningMiddleware
      end
    end
    context "when there is an existing trace" do
      before { RequestTracer::Trace.push trace.to_h }
      it "does not pass the trace from the main process to the worker and records the worker" do
        TraceableJob.perform_async('foo')
        expect(result_checker.traces).to eq([{}])
      end
    end
  end
  context "when asynchronously calling a job with missing client middleware" do
    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ThreadSpawningMiddleware
        chain.add RequestTracer::Integration::SidekiqHandler::ServerMiddleware
      end
    end
    context "when there is an existing trace" do
      before { RequestTracer::Trace.push trace.to_h }
      it "does not pass the trace from the main process to the worker and records the worker" do
        TraceableJob.perform_async('foo')
        expect(result_checker.traces).to eq([{}])
      end
    end
  end
end
