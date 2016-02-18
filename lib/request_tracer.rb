module RequestTracer
  B3_REQUIRED_FIELDS = %w(trace_id parent_span_id span_id)
  B3_REQUIRED_FIELDS_FROM_SHORT_NAMES = B3_REQUIRED_FIELDS.map {|f| [f.gsub("_", ""), f] }.to_h
  B3_REQUIRED_HEADERS = B3_REQUIRED_FIELDS.map {|f| "HTTP_X_B3_#{f.gsub("_", "").upcase}" }
  B3_REQUIRED_FIELD_HEADER_MAP = B3_REQUIRED_FIELDS.zip(B3_REQUIRED_HEADERS).to_h
  B3_REQUIRED_HEADER_FIELD_MAP = B3_REQUIRED_HEADERS.zip(B3_REQUIRED_FIELDS).to_h
  B3_OPT_HEADERS = %w[HTTP_X_B3_FLAGS]

  def self.integrate_with(*services)
    services.each do |service|
      require_relative "request_tracer/integration/#{service}_handler"
      class_name = service.to_s.split('_').collect(&:capitalize).join + 'Handler'
      integration_module = RequestTracer::Integration.const_get(class_name)
      integration_module.activate
    end
  end
end
