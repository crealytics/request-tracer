
require 'rack/test'
require 'request_tracer/trace'
require 'request_tracer/integration/faraday_handler'
require 'webmock/rspec'

describe RequestTracer::Integration::FaradayHandler do
  include RequestTracer::Integration::Base
  RequestTracer.integrate_with(:faraday)
  before(:all) { WebMock.disable_net_connect! }

  let(:trace) { RequestTracer::Trace.create }

  before do
    RequestTracer::Trace.clear
    stub_request(:any, "www.example.com")
    allow(RequestTracer::Trace).to receive(:record) {|&block| block.call(trace) }
    Faraday.new("http://www.example.com/").get
  end

  context "when no previous trace existed on the stack" do
    it "sets fresh trace headers on the outgoing call" do
      expect(WebMock).to have_requested(:get, "www.example.com").
        with(headers: extract_headers_from_fields(trace.to_h))
    end
  end
end
