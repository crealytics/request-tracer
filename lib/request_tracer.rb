module RequestTracer
  def self.integrate_with(*services)
    services.each do |service|
      require_relative "request_tracer/integration/#{service}_handler"
      class_name = service.to_s.split('_').collect(&:capitalize).join + 'Handler'
      integration_module = RequestTracer::Integration.const_get(class_name)
      integration_module.activate
    end
  end
end
