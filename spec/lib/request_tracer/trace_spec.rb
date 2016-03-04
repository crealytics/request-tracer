require 'request_tracer/trace'

describe RequestTracer::Trace do
  let(:trace_stack_size) { rand(2) }
  let(:trace_stack) do
    (1..trace_stack_size).inject([]) do |stack, i|
      stack + [(stack.last && stack.last.next_id) || described_class.create]
    end
  end
  before do
    described_class.clear
    trace_stack.each {|s| described_class.push(s.to_h) }
  end
  context '#record', generative: true, order: :generative do
    def record(&blk)
      described_class.record(&blk)
    end
    it 'generates a new span_id for the scope of the block' do
      temp_span = record do |t|
        expect(t.span_id).not_to eq(trace_stack.last && trace_stack.last.span_id)
        expect(described_class.latest).to eq(t)
        t
      end
      expect(described_class.latest).not_to eq(temp_span)
    end
    it 'takes the old span_id as the parent_span_id' do
      temp_span = record do |t|
        expect(t.parent_id).to eq(trace_stack.last && trace_stack.last.span_id)
        t
      end
      expect(described_class.latest && described_class.latest.span_id).to eq(temp_span.parent_id)
    end
    context 'when no previous trace exists' do
      let(:trace_stack_size) { 0 }
      it 'generates a new trace_id' do
        record do |t|
          expect(t.trace_id.i64.to_s).to match /[0-9a-z]+/i
        end
      end
    end
    context 'when a previous trace exists' do
      let(:trace_stack_size) { 1 }
      it 'reuses the existing trace_id' do
        record do |t|
          expect(t.trace_id).to eq(trace_stack.last.trace_id)
        end
      end
    end
  end
  context '#push(trace_hash)', generative: true, order: :generative do
    def push(&blk)
      described_class.push(previous_trace_hash, &blk)
    end
    shared_examples "returning the block value" do
      let(:block_value) { rand(1000) }
      it 'returns the value from the block' do
        returned = push {|t| block_value }
        expect(returned).to eq(block_value)
      end
    end
    context 'when trace_hash contains a previous trace' do
      let(:previous_trace) { described_class.create}
      let(:previous_trace_hash) { previous_trace.to_h }
      it_behaves_like "returning the block value"
      it 'keeps the span_id' do
        push do |t|
          expect(t.span_id).to eq(previous_trace.span_id)
        end
      end
      it 'keeps the parent_span_id' do
        push do |t|
          expect(t.parent_id).to eq(previous_trace.parent_id)
        end
      end
      it 'keeps the trace_id' do
        push do |t|
          expect(t.trace_id).to eq(previous_trace.trace_id)
        end
      end
    end
    context 'when no previous trace exists' do
      let(:previous_trace_hash) { {} }
      it_behaves_like "returning the block value"
      it 'creates a new span_id' do
        push do |t|
          expect(t.span_id.i64.to_s).to match /[0-9a-z]+/i
        end
      end
      it 'creates a new trace_id' do
        push do |t|
          expect(t.trace_id.i64.to_s).to match /[0-9a-z]+/i
        end
      end
      it 'does not set a parent_span_id' do
        push do |t|
          expect(t.parent_id).to eq(nil)
        end
      end
    end
    context 'when called with nil' do
      let(:previous_trace_hash) { nil }
      it_behaves_like "returning the block value"
    end
  end
end
