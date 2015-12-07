require 'spec_helper'
require 'json'
require 'support/test_app'
require 'open-uri'
require 'timeout'
require 'webmock'

# In this spec we are going to run two applications and check that they are creating traces
# And that the traces created by one application are sent to the other application
RSpec::Matchers.define_negated_matcher :a_value_different_from, :eq

describe 'integrations' do
  before(:all) do
    WebMock.allow_net_connect!
    @port1 = 4444
    @port2 = 4445
    ru_location = File.expand_path('../support/test_app_config.ru', File.dirname(__FILE__))
    @pipe1 = IO.popen(["rackup", ru_location, "-p", @port1.to_s, err: [:child, :out]])
    @pipe2 = IO.popen(["rackup", ru_location, "-p", @port2.to_s, err: [:child, :out]])
    sleep(2)
    if RUBY_PLATFORM == 'java'
      sleep(20) #Jruby starts slow
    end
  end

  let(:base_url1) { "http://localhost:#{@port1}" }
  let(:base_url2) { "http://localhost:#{@port2}" }

  after(:all) do
    Process.kill("KILL", @pipe1.pid)
    Process.kill("KILL", @pipe2.pid)
  end

  after { read_all_pipes }

  def read_without_blocking(io, maxlen = 4096)
    io.read_nonblock(maxlen)
  rescue => e
    ""
  end
  let(:response) { open(url) {|f| f.read } rescue(raise "Could not read from #{url}.\nOutput from services:\n#{read_all_pipes}") }
  def read_all_pipes
    read_without_blocking(@pipe1) + "\n" + read_without_blocking(@pipe2)
  end
  let(:services_output) {
    response
    read_all_pipes
  }
  let(:traces) do
    all_output = services_output
    all_output.split("\n").grep(/^%%%/).sort.map {|t| JSON.parse(t.gsub(/^%%% \d+/, ""))}
  end
  shared_examples_for "responding to a REST call without tracing headers" do
    it "does not modify the original response body" do
      expect(response).to eq(expected_response)
    end
    it "has a trace with non-empty trace_id and span_id and an empty parent_span_id" do
      expect(traces[0]).to include(
        'trace_id' => a_string_matching(/.+/),
        'span_id' => a_string_matching(/.+/),
        # The parent_span_id should be empty, as a 0-level trace has no parent.
        'parent_span_id' => ""
      )
    end
  end
  shared_examples_for "responding to a transitive REST call with tracing headers" do
    it "has the same trace_id as the caller, the caller's span id as parent_span_id and a fresh span_id" do
      expect(traces[1]).to include(
        'trace_id' => traces[0]['trace_id'],
        'parent_span_id' => traces[0]['span_id'],
        'span_id' => a_value_different_from(traces[0]['span_id'])
      )
    end
    it { expect([traces[1]['trace_id'], traces[1]['parent_span_id']]).not_to include(traces[1]['span_id']) }
  end
  context "when doing a simple service call" do
    let(:url) { "#{base_url1}/hello_world" }
    let(:expected_response) { 'Hello World' }
    it { expect(traces.size).to eq(1) }
    it_behaves_like "responding to a REST call without tracing headers"
  end

  context "when doing a service call that calls another service" do
    let(:url) { "#{base_url1}/ouroboros?out_port=#{@port2}" }
    let(:expected_response) { 'Ouroboros says Hello World' }
    it_behaves_like "responding to a REST call without tracing headers"
    it_behaves_like "responding to a transitive REST call with tracing headers"
    it { expect(traces).to satisfy {|t| t.size == 2} }
  end

end
