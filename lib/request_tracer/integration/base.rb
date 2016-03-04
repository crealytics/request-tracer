module RequestTracer
  module Integration
    module Base
      HEADER_REGEX = /HTTP_X_B3_(.*)/
      def extract_fields_from_headers(header_hash)
        header_hash.map do |k,v|
          special_header = HEADER_REGEX.match(k)
          special_header && [B3_REQUIRED_FIELDS_FROM_SHORT_NAMES[special_header[1].downcase], v]
        end.compact.to_h
      end
      def extract_headers_from_fields(field_hash)
        B3_REQUIRED_FIELDS.map {|f| ["X_B3_" + f.gsub("_", "").upcase, field_hash[f]]}.to_h
      end
    end
  end
end
