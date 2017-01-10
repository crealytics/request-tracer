
require 'rack/test'
require 'request_tracer/trace'
require 'request_tracer/integration/faraday_handler'
require 'webmock/rspec'

describe RequestTracer::Integration::FaradayHandler do
  include RequestTracer::Integration::Base
  RequestTracer.integrate_with(:faraday)
  before(:all) { WebMock.disable_net_connect! }

  let(:trace) { RequestTracer::Trace.create }

  shared_examples_for "adding a tracing request header" do |adapter|
    before do
      RequestTracer::Trace.clear
      stub_request(:any, "www.example.com")
      allow(RequestTracer::Trace).to receive(:record) {|&block| block.call(trace) }
      client = Faraday.new("http://www.example.com/") do |conn|
        conn.use :tracing
        conn.adapter adapter
      end
      client.get
    end

    context "when no previous trace existed on the stack" do
      it "sets fresh trace headers on the outgoing call" do
        expect(WebMock).to have_requested(:get, "www.example.com").
          with(headers: extract_headers_from_fields(trace.to_h))
      end
    end
  end
  context "with the default adapter" do
    it_behaves_like "adding a tracing request header", :typhoeus
  end
  context "with the typhoeus adapter" do
     require 'typhoeus/adapters/faraday'
    it_behaves_like "adding a tracing request header", Faraday.default_adapter
  end
end
