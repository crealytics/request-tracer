module RequestTracer
  module Integration
    module Base
      B3_REQUIRED_FIELDS = %w(trace_id parent_span_id span_id)
      B3_REQUIRED_FIELDS_FROM_SHORT_NAMES = B3_REQUIRED_FIELDS.map {|f| [f.gsub("_", ""), f] }.to_h
      B3_REQUIRED_HEADERS = B3_REQUIRED_FIELDS.map {|f| "HTTP_X_B3_#{f.gsub("_", "").upcase}" }
      B3_REQUIRED_FIELD_HEADER_MAP = B3_REQUIRED_FIELDS.zip(B3_REQUIRED_HEADERS).to_h
      B3_REQUIRED_HEADER_FIELD_MAP = B3_REQUIRED_HEADERS.zip(B3_REQUIRED_FIELDS).to_h
      B3_OPT_HEADERS = %w[HTTP_X_B3_FLAGS]
      def extract_fields_from_headers(header_hash)
        header_hash.map do |k,v|
          special_header = /HTTP_X_B3_(.*)/.match(k)
          special_header && [B3_REQUIRED_FIELDS_FROM_SHORT_NAMES[special_header[1].downcase], v]
        end.compact.to_h
      end
      def extract_headers_from_fields(field_hash)
        B3_REQUIRED_FIELDS.map {|f| ["X_B3_" + f.gsub("_", "").upcase, field_hash[f]]}.to_h
      end
    end
  end
end
