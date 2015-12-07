require 'rack/mock'
require 'rack/test'
require 'spec_helper'
require 'request_tracer/trace'
require 'logger'
require 'webmock/rspec'
require 'rest-client'

describe RequestTracer::Integration::RestClientHandler do
  include RequestTracer::Integration::Base
  RequestTracer.integrate_with(:rest_client)
  before(:all) { WebMock.disable_net_connect! }
  before do
    stub_request(:any, "www.example.com")
  end

  let(:trace) { RequestTracer::Trace.latest }
  it "should have set the headers on the outgoing call" do
    RestClient.get("www.example.com")
    expect(WebMock).to have_requested(:get, "www.example.com").
      with(headers: extract_headers_from_fields(trace.to_h))
  end
end
