module RequestTracer
  module Trace
    extend self
    TRACE_ID_UPPER_BOUND = 2 ** 64
    TRACE_STACK = :trace_stack

    class Annotation
      attr_reader :name, :time
      def initialize(name, time = DateTime.now)
        @name = name
        @time = time
      end
    end

    # A span represents one specific method call
    class SpanId
      HEX_REGEX = /^[a-f0-9]{16}$/i
      MAX_SIGNED_I64 = 9223372036854775807
      MASK = (2 ** 64) - 1

      def self.from_value(v)
        if v.is_a?(String) && v =~ HEX_REGEX
          new(v.hex)
        elsif v.is_a?(Numeric)
          new(v)
        elsif v.is_a?(SpanId)
          v
        end
      end

      attr_reader :value, :i64
      def initialize(value)
        @value = value
        @i64 = if @value > MAX_SIGNED_I64
          -1 * ((@value ^ MASK) + 1)
        else
          @value
        end
      end

      def ==(other_span)
        other_span && (other_span.value == @value)
      end
      def to_s; "%016x" % @value; end
      def to_i; @i64; end
    end

    # A trace is a set of spans that are associated with the same request
    class TraceId
      attr_reader :trace_id, :parent_id, :span_id
      def self.spawn_from_hash(h)
        span_id = Trace.generate_id
        self.new(h["trace_id"] || span_id, h["span_id"], Trace.generate_id)
      end
      def self.create(h)
        self.new(h["trace_id"], h["parent_span_id"], h["span_id"])
      end
      def initialize(trace_id, parent_id, span_id)
        @trace_id = SpanId.from_value(trace_id)
        @parent_id = parent_id && SpanId.from_value(parent_id)
        @span_id = SpanId.from_value(span_id)
      end

      def next_id
        TraceId.new(@trace_id, @span_id, Trace.generate_id)
      end

      def to_s
        "TraceId(trace_id = #{@trace_id.to_s}, parent_id = #{@parent_id.to_s}, span_id = #{@span_id.to_s}"
      end

      def to_h
        {"trace_id" => @trace_id.to_s, "parent_span_id" => (@parent_id || "").to_s, "span_id" => @span_id.to_s}
      end
      def [](key)
        to_h[key]
      end
      def to_json
        to_h.to_json
      end
    end

    def create
      span_id = generate_id
      TraceId.new(span_id, nil, span_id)
    end

    def latest
      stack.last
    end

    def latest_or_create
      latest || stack.push(create)
    end

    def push(trace_info)
      return yield unless trace_info
      trace = if trace_info.include?("trace_id") && trace_info.include?("span_id")
        TraceId.create(trace_info)
      else
        TraceId.spawn_from_hash(trace_info)
      end
      stack.push(trace)
      if block_given?
        begin
          yield trace
        ensure
          pop
        end
      end
    end

    def pop
      stack.pop
    end

    def clear
      stack.clear
    end

    def unwind
      if block_given?
        begin
          saved_stack = stack.dup
          yield
        ensure
          stack = saved_stack
        end
      end
    end

    def record(annotation = nil, &block)
      tracer.record((latest && latest.next_id) || create, annotation, &block)
    end

    def tracer=(tracer)
      @tracer = tracer
    end

    def generate_id
      rand(TRACE_ID_UPPER_BOUND)
    end


    private

    # "stack" acts as a thread local variable and cannot be shared between
    # threads.
    def stack=(stack)
      Thread.current[TRACE_STACK] = stack
    end

    def stack
      Thread.current[TRACE_STACK] ||= []
    end

    def tracer
      @tracer ||= DefaultTracer.new
    end

  end
  class NullTracer
    def record(*args, &block)
      block.call
    end
  end

  class DefaultTracer
    def record(latest_trace, annotation, &block)
      Trace.push(latest_trace.to_h) do |trace|
        block.call(trace)
      end
    end
  end
end
