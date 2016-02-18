require 'rack/mock'
require 'rack/test'
require 'spec_helper'
require 'request_tracer/integration/rack_handler'
require 'logger'

describe RequestTracer::Integration::RackHandler do
  include Rack::Test::Methods
  include RequestTracer::Integration::Base
  let(:tracer) { double("tracer") }

  def middleware(service, config={})
    RequestTracer::Integration::RackHandler.new(service, config.merge(tracer: tracer))
  end

  def app
    middleware(service)
  end

  let(:service) do
    lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['hello']] }
  end

  before do
    allow(tracer).to receive(:record) {|&block| block.call }
  end

  shared_examples_for 'traces the request' do
    before do
      trace_headers.each {|k, v| header(k, v)}
    end
    it 'traces the request' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('hello')
      expect(tracer).to have_received(:record).with(extract_fields_from_headers(trace_headers))
    end
  end

  let(:trace_headers) { RequestTracer::B3_REQUIRED_HEADERS.map {|a| [a, rand(1000)] }.to_h }
  context 'Zipkin headers are passed to the middleware' do
    subject { middleware(service) }
    it_behaves_like "traces the request"
  end
end
